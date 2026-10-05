# cuda-gdb extensions for gdb-dashboard, modeled on pwndbg's context view.
#
# Panels: Cuda (focus, lane strip, exceptions), Code (disassembly with register
# values), Locals (variables with address space, pointer targets, warp spread),
# Host (host threads and where they wait). Command: warp EXPR.
#
# CUDA state comes from cuda-gdb's built-in Python module `gdb.cuda`; nothing
# here parses `info cuda ...` text.
#
# gdb-dashboard sources this file into its own namespace, so gdb, Dashboard, R,
# Registers, ansi, and divider are globals defined by the dashboard script.
# ruff: noqa: F821
# mypy: ignore-errors

import re

# Colors follow pwndbg's split:
# - semantic labels use the 16 basic ANSI colors, so the terminal theme decides
#   the exact shade (pwndbg: stack yellow, heap blue, code red, data purple);
# - code and numbers use the Pygments style of the Source panel (monokai by
#   default), the same scheme pwndbg uses for its disassembly.
C = {
    "red": "31",
    "green": "32",
    "yellow": "33",
    "blue": "34",
    "magenta": "35",
    "cyan": "36",
}

SPACE_STYLE = {
    "register": C["cyan"],
    "local": C["yellow"],  # per-thread stack
    "shared": C["magenta"],  # per-block writable data
    "global": C["blue"],  # device heap
    "generic": C["blue"],
    "parameter": C["red"],  # read-only kernel parameters
    "const": C["red"],
    "host": "",
    "host+device": C["green"],
}

_SYNTAX_FALLBACK = {"mnemonic": "32", "register": "36", "number": "35", "guard": "33"}


def syntax_style(role):
    """SGR code for a code token role, taken from the dashboard's Pygments style."""
    try:
        from pygments.styles import get_style_by_name
        from pygments.token import Keyword, Name, Number

        style = get_style_by_name(R.syntax_highlighting or "monokai")
        token = {"mnemonic": Name.Function, "register": Keyword, "number": Number, "guard": Name.Decorator}[role]
        color = style.style_for_token(token)["color"]
        if color:
            r, g, b = (int(color[i : i + 2], 16) for i in (0, 2, 4))
            return f"38;2;{r};{g};{b}"
    except Exception:
        pass
    return _SYNTAX_FALLBACK[role]


_SPACE_RE = re.compile(r"@(\w+)")


def cuda_focus():
    """Physical CUDA focus, or None when the selected thread is a host thread."""
    cuda = getattr(gdb, "cuda", None)
    if cuda is None:
        return None
    try:
        return cuda.get_focus_physical()
    except gdb.error, RuntimeError, TypeError:
        return None


class _KeepFocus:
    """Restore the CUDA focus (or host thread) and selected frame on exit."""

    def __enter__(self):
        self.focus = cuda_focus()
        self.thread = gdb.selected_thread()
        self.level = gdb.selected_frame().level()
        return self

    def __exit__(self, *exc):
        # restore the host thread first: execution commands resume gdb's selected
        # thread, and the CUDA focus alone does not select it
        if self.thread is not None and self.thread.is_valid():
            self.thread.switch()
        if self.focus is not None:
            gdb.cuda.set_focus_physical(self.focus)
        frame = gdb.newest_frame()
        for _ in range(self.level):
            frame = frame.older() or frame
        frame.select()
        return False


def space_of(value):
    """Address space holding `value` itself: the outermost qualifier of its type.

    'const @generic float * @parameter' is a pointer stored in parameter space
    that points to generic memory, so the last qualifier is the one that counts.
    """
    spaces = _SPACE_RE.findall(str(value.type))
    return spaces[-1] if spaces else "host"


def space_tag(space, width=0):
    return ansi(("@" + space).ljust(width), SPACE_STYLE.get(space, ""))


def short(value, elements=8, limit=0):
    """One-line value text, cut to `limit` characters when limit > 0."""
    try:
        text = value.format_string(pretty_structs=False, pretty_arrays=False, max_elements=elements, repeat_threshold=0)
    except gdb.error as e:
        text = f"<{e}>"
    text = " ".join(text.split())
    if limit and len(text) > limit:
        text = text[: max(limit - 1, 1)] + "…"
    return text


def _elements(pointer, count):
    items = ", ".join(short((pointer + i).dereference(), 4) for i in range(count))
    return "{" + (items if len(items) <= 64 else items[:63] + "…") + ", …}"


def _device_view(value, target):
    """Re-read a host-typed pointer as @global; None if the device cannot see it.

    A cudaMalloc pointer held in a host variable reads as zeros from host memory
    without any error, so the device view is the one worth showing.
    """
    if getattr(gdb, "cuda", None) is None or cuda_focus() is not None:
        return None
    try:
        pointer = gdb.parse_and_eval(f"(@global {target.unqualified()} *)0x{int(value):x}")
        pointer.dereference().fetch_lazy()
        return pointer
    except gdb.error:
        return None


def _host_readable(address):
    """True when `address` lies in a readable mapping of the inferior (/proc/PID/maps)."""
    try:
        with open(f"/proc/{gdb.selected_inferior().pid}/maps") as maps:
            for line in maps:
                span, perms = line.split()[:2]
                low, high = (int(x, 16) for x in span.split("-"))
                if low <= address < high:
                    return perms.startswith("r")
    except OSError:
        pass
    return False


def pointee(value, count=6):
    """Pointer target summary like pwndbg's '—▸' chain: '@global {a, b, ...}'."""
    target = value.type.strip_typedefs().target()
    if target.strip_typedefs().code in (gdb.TYPE_CODE_VOID, gdb.TYPE_CODE_FUNC) or target.sizeof == 0:
        return None
    if int(value) == 0:
        return None, ansi("NULL", syntax_style("number"))
    spaces = _SPACE_RE.findall(str(value.type))
    space = spaces[0] if spaces else "host"
    try:
        if target.strip_typedefs().code == gdb.TYPE_CODE_INT and target.sizeof == 1:
            body = repr(value.string(length=48))
        else:
            body = None
            if space == "host":
                device = _device_view(value, target)
                if device is not None:
                    body = _elements(device, count)
                    # UVA reserves device-only ranges as inaccessible (---p) host
                    # mappings; pinned host memory is a readable mapping
                    space = "host+device" if _host_readable(int(value)) else "global"
            if body is None:
                body = _elements(value, count)
    except gdb.MemoryError, gdb.error:
        body = ansi("<unreadable>", R.style_error)
    return space, "{} {} {}".format(ansi("—▸", R.style_low), space_tag(space), body)


def frame_symbols(frame):
    """Arguments first, then locals, innermost declaration wins."""
    try:
        block = frame.block()
    except RuntimeError:
        return []
    seen, args, local = set(), [], []
    while block is not None:
        for sym in block:
            if not (sym.is_variable or sym.is_argument) or sym.name in seen:
                continue
            seen.add(sym.name)
            (args if sym.is_argument else local).append(sym)
        if block.function is not None:
            break
        block = block.superblock
    return args + local


# ---------------------------------------------------------------------------


def _focus_key():
    focus = cuda_focus()
    if focus is not None:
        return str(focus)
    thread = gdb.selected_thread()
    return f"host {thread.num}" if thread is not None else None


class Cuda(Dashboard.Module):
    """CUDA focus: device, logical/physical coordinates, lane strip, exceptions."""

    # focus drawn by the last render; a different focus at the prompt means the
    # user ran `cuda ...` or `thread N`, so the panels are redrawn for it
    drawn_focus = None

    def label(self):
        return "CUDA"

    def lines(self, term_width, term_height, style_changed):
        Cuda.drawn_focus = _focus_key()
        focus = cuda_focus()
        if focus is None:
            thread = gdb.selected_thread()
            name = f" ({thread.name})" if thread and thread.name else ""
            return [ansi("host", "1;" + C["yellow"]) + " thread {}{}".format(thread.num if thread else "?", name)]
        dev, warp = focus.device, focus.warp
        logical = gdb.cuda.get_focus_logical()
        out = [
            "{} {}  {}  {}".format(
                ansi(f"device {focus.device_id}", "1;" + C["yellow"]),
                dev.name,
                ansi(dev.sm_type, C["cyan"]),
                ansi(f"{dev.num_sms} SMs", R.style_low),
            ),
            "{}  {}".format(
                ansi(
                    f"kernel {logical.kernel_id} grid {logical.grid_id}"
                    f"  block {logical.block_idx}  thread {logical.thread_idx}",
                    "1;" + C["cyan"],
                ),
                ansi(
                    f"sm {focus.sm_id} warp {focus.warp_id} lane {focus.lane_id}"
                    f"  regs/thread {warp.registers_allocated}  smem {warp.shared_memory_size} B",
                    R.style_low,
                ),
            ),
        ]
        # 32-character strip: █ active, ▒ divergent, · invalid; focused lane reversed
        strip, active, divergent = "", 0, 0
        for lane in warp.lanes():
            if not lane.is_valid:
                ch = ansi("·", R.style_low)
            elif lane.is_active:
                active += 1
                ch = ansi("█", "7;" + C["green"] if lane.lane_id == focus.lane_id else C["green"])
            else:
                divergent += 1
                ch = ansi("▒", "7;" + C["yellow"] if lane.lane_id == focus.lane_id else C["yellow"])
            strip += ch
        out.append(f"lanes {strip}  {active} active  {divergent} divergent")
        # pwndbg "LAST SIGNAL": device exceptions
        exception = focus.lane.exception or focus.sm.exception
        errorpc = warp.errorpc or focus.sm.errorpc
        if exception or errorpc:
            line = f"EXCEPTION  {self.exception_name(exception)}"
            if errorpc:
                line += f"  errorpc 0x{errorpc:x}"
                if errorpc != gdb.selected_frame().pc():
                    line += " (faulting instruction; pc has moved on)"
            out.append(ansi(line, R.style_error))
        return out

    @staticmethod
    def exception_name(code):
        # gdb.cuda only gives the number; gdb's stop report carries the name
        text = gdb.execute("info program", to_string=True)
        match = re.search(r"signal (CUDA_EXCEPTION_\d+), ([^.\n]+)", text)
        if match:
            return f"{match.group(2)} ({match.group(1)})"
        return f"CUDA_EXCEPTION_{code}" if code else "unknown"


class Code(Dashboard.Module):
    """Disassembly around the PC; each line lists the current values of the registers it names."""

    def label(self):
        return "Code"

    def lines(self, term_width, term_height, style_changed):
        frame = gdb.selected_frame()
        arch = frame.architecture()
        pc = frame.pc()
        try:
            block = frame.block()
            while block.function is None and block.superblock is not None:
                block = block.superblock
            start = block.start
        except RuntimeError:
            start = pc
        # disassemble from the function start so variable-length (x86) decoding stays aligned
        before = arch.disassemble(max(start, pc - 64 * self.context), pc) if pc > start else []
        if before and before[-1]["addr"] == pc:
            before = before[:-1]
        window = before[-self.context :] + arch.disassemble(pc, count=self.height - min(len(before), self.context))
        names = {r.name for r in arch.registers()}
        focus = cuda_focus()
        errorpc = (focus.warp.errorpc or focus.sm.errorpc) if focus is not None else None
        out = []
        for insn in window:
            current = insn["addr"] == pc
            marker = ansi("►", "1;" + C["green"]) if current else " "
            if insn["addr"] == errorpc:
                marker = ansi("✗", R.style_error)
            offset = "+{}".format(insn["addr"] - start) if insn["addr"] >= start else ""
            asm = self.colorize(insn["asm"], names)
            # addresses matter little here: plain text, bold on the current line
            address = ansi("0x{:x}".format(insn["addr"]), "1" if current else R.style_low)
            line = "{} {} {}  {}".format(marker, address, ansi(f"{offset:>6}", R.style_low), asm)
            if current or insn["addr"] == errorpc or self.annotate_all:
                notes = self.register_values(insn["asm"], names, frame)
                if notes:
                    line += "   " + ansi(notes, R.style_low)
            out.append(line)
        return out

    @staticmethod
    def operands(asm, names):
        seen = []
        for token in re.findall(r"%?[A-Za-z_][A-Za-z0-9_]*", asm):
            token = token.lstrip("%")
            if token in names and token not in seen and token not in ("pc", "RZ", "URZ", "PT", "UPT"):
                seen.append(token)
        return seen

    def register_values(self, asm, names, frame):
        notes = []
        for name in self.operands(asm, names)[:4]:
            try:
                value = frame.read_register(name)
                notes.append(f"{name}={Registers.format_value(value)}")
            except gdb.error, ValueError:
                pass
        return "  ".join(notes)

    @staticmethod
    def colorize(asm, names):
        def paint(match):
            token = match.group(0)
            if token.lstrip("%") in names:
                return ansi(token, syntax_style("register"))
            if re.fullmatch(r"-?(0x[0-9a-fA-F]+|\d+)", token):
                return ansi(token, syntax_style("number"))
            return token

        head, _, tail = asm.partition(" ")
        if head.startswith("@"):  # predicated SASS: @P0 OPCODE ...
            pred, _, tail = tail.partition(" ")
            head, tail = f"{head} {pred}", tail
            op, _, tail = tail.partition(" ")
            head = "{} {}".format(ansi(head.split()[0], syntax_style("guard")), ansi(op, syntax_style("mnemonic")))
        else:
            head = ansi(head, syntax_style("mnemonic"))
        return head + " " + re.sub(r"-?0x[0-9a-fA-F]+|%?[A-Za-z_][\w]*|-?\d+", paint, tail)

    def attributes(self):
        return {
            "height": {"doc": "Instructions to show.", "default": 12, "type": int},
            "context": {"doc": "Instructions to show before the PC.", "default": 4, "type": int},
            "annotate-all": {
                "doc": "Annotate register values on every line, not only the PC.",
                "default": False,
                "name": "annotate_all",
                "type": bool,
            },
        }


class Locals(Dashboard.Module):
    """Arguments and locals with storage space, pointer targets, and spread across the warp."""

    def label(self):
        return "Locals"

    def lines(self, term_width, term_height, style_changed):
        frame = gdb.selected_frame()
        symbols = frame_symbols(frame)
        if not symbols:
            return [ansi("no symbols (build with -g -G)", R.style_low)]
        focus = cuda_focus()
        spread = self.warp_spread(symbols) if focus is not None and self.warp else {}
        legend = "  ".join(space_tag(s) for s in ("register", "local", "shared", "global", "parameter"))
        out = [ansi("LEGEND ", R.style_low) + legend] if focus is not None else []
        width = max(len(s.name) for s in symbols)
        for sym in symbols:
            try:
                value = sym.value(frame)
                space = space_of(value)
                text = short(value, limit=self.limit)
                code = value.type.strip_typedefs().code
                if code == gdb.TYPE_CODE_PTR:
                    target = pointee(value)
                    if target:
                        # like pwndbg, the address takes the color of the memory it points to
                        target_space, summary = target
                        text = "{} {}".format(ansi(text, SPACE_STYLE.get(target_space, "")), summary)
                elif code in (gdb.TYPE_CODE_INT, gdb.TYPE_CODE_FLT, gdb.TYPE_CODE_BOOL):
                    text = ansi(text, syntax_style("number"))
            except (gdb.error, RuntimeError) as e:
                space, text = "?", ansi(f"<{e}>", R.style_error)
            kind = ansi("arg", R.style_low) if sym.is_argument else ansi("loc", R.style_low)
            line = f"{kind} {ansi(sym.name.ljust(width), R.style_high)}  {space_tag(space, 10)}  {text}"
            if sym.name in spread:
                line += "   " + spread[sym.name]
            out.append(line)
        return out

    @staticmethod
    def warp_spread(symbols):
        """Evaluate every symbol on each active lane: 'uniform', or range and distinct count."""
        focus = cuda_focus()
        lanes = focus.warp.active_lanes()
        # gdb values are lazy: read them while the lane is focused, not after restoring
        texts = {s.name: [] for s in symbols}
        numbers = {s.name: [] for s in symbols}
        with _KeepFocus():
            for lane in lanes:
                gdb.cuda.set_focus_physical(lane.physical())
                frame = gdb.selected_frame()
                for sym in symbols:
                    try:
                        value = sym.value(frame)
                        texts[sym.name].append(short(value))
                        if value.type.strip_typedefs().code in (gdb.TYPE_CODE_INT, gdb.TYPE_CODE_FLT):
                            numbers[sym.name].append(float(value))
                    except gdb.error, RuntimeError:
                        pass
        spread = {}
        for name, vals in texts.items():
            if len(vals) < 2:
                continue
            distinct = len(set(vals))
            if distinct == 1:
                spread[name] = ansi("warp: uniform", R.style_low)
                continue
            nums = numbers[name]
            if len(nums) == len(vals):
                label = f"warp: [{min(nums):g} .. {max(nums):g}] {distinct} distinct"
            else:
                label = f"warp: {distinct} distinct"
            spread[name] = ansi(label, C["yellow"])
        return spread

    def attributes(self):
        return {
            "warp": {"doc": "Evaluate each variable on all active lanes of the warp.", "default": True, "type": bool},
            "limit": {"doc": "Maximum characters of a value before it is cut.", "default": 72, "type": int},
        }


class Host(Dashboard.Module):
    """Host threads and the innermost named frame each one is in (pwndbg THREADS)."""

    def label(self):
        return "Host"

    def lines(self, term_width, term_height, style_changed):
        selected = gdb.selected_thread()
        in_device = cuda_focus() is not None
        out = []
        with _KeepFocus():
            for thread in sorted(gdb.selected_inferior().threads(), key=lambda t: t.num):
                thread.switch()
                out.append(self.describe(thread, selected, in_device))
        return out

    @staticmethod
    def describe(thread, selected, in_device):
        api, user, top = None, None, None
        frame = gdb.newest_frame()
        while frame is not None and user is None:
            name = frame.name()
            sal = frame.find_sal()
            if top is None:
                top = name or gdb.solib_name(frame.pc()) or f"0x{frame.pc():x}"
            if sal.symtab is not None and sal.line:
                user = "{} {}:{}".format(name, sal.symtab.filename.rsplit("/", 1)[-1], sal.line)
            elif name and name.startswith(("cuda", "cu")):
                api = name  # keep the outermost one: the runtime call the program made
            frame = frame.older()
        where = user or ansi("in " + top.rsplit("/", 1)[-1], R.style_low)
        if api:
            where = "{} {} {}".format(ansi(api, C["yellow"]), ansi("←", R.style_low), where)
        marker = ansi("►", "1;" + C["green"]) if (not in_device and thread == selected) else " "
        return "{} {:>2} {:<18} {}".format(marker, thread.num, (thread.name or "")[:18], where)


def _redraw_on_focus_change():
    try:
        if Cuda.drawn_focus is None or not gdb.selected_inferior().pid:
            return
        if _focus_key() != Cuda.drawn_focus:
            gdb.execute("dashboard")
    except gdb.error:
        pass


gdb.events.before_prompt.connect(_redraw_on_focus_change)


# ---------------------------------------------------------------------------


class Warp(gdb.Command):
    """Evaluate EXPR on every lane of the focused warp: warp EXPR"""

    def __init__(self):
        super().__init__("warp", gdb.COMMAND_DATA, gdb.COMPLETE_EXPRESSION)

    def invoke(self, arg, from_tty):
        # one table is a single answer; do not stop halfway at the pager prompt
        pagination = gdb.parameter("pagination")
        gdb.execute("set pagination off", to_string=True)
        try:
            self.show(arg)
        finally:
            gdb.execute("set pagination {}".format("on" if pagination else "off"), to_string=True)

    def show(self, arg):
        if not arg:
            raise gdb.GdbError("usage: warp EXPR")
        focus = cuda_focus()
        if focus is None:
            raise gdb.GdbError("focus is not on a CUDA thread")
        rows = []
        with _KeepFocus():
            for lane in focus.warp.lanes():
                value = None
                if lane.is_valid and lane.is_active:
                    gdb.cuda.set_focus_physical(lane.physical())
                    try:
                        value = short(gdb.parse_and_eval(arg), 16)
                    except gdb.error as e:
                        value = f"<{e}>"
                state = "active" if lane.is_active else ("divergent" if lane.is_valid else "invalid")
                rows.append((lane.lane_id, str(lane.thread_idx) if lane.is_valid else "-", state, value))
        print(f"device {focus.device_id} sm {focus.sm_id} warp {focus.warp_id}: {arg}")
        if all(state == "active" for _, _, state, _ in rows) and len({v for *_, v in rows}) == 1:
            print(f"  all {len(rows)} lanes: {rows[0][3]}")
            return
        # short values: lane-major grid (lanes 0-7 in the first column) to stay on one screen
        cells = []
        for lane, _tid, state, value in rows:
            text = value if state == "active" else ("·" if state == "invalid" else "▒ divergent")
            mark = "*" if lane == focus.lane_id else " "
            cells.append((f"{mark}{lane:>2} {text}", state))
        width = max(len(c) for c, _ in cells) + 2
        columns = max(1, min(4, Dashboard.get_term_size()[0] // width))
        if columns == 1:
            for lane, tid, state, value in rows:
                mark = "*" if lane == focus.lane_id else " "
                print("{}{:>3} {:>10} {:<9} {}".format(mark, lane, tid, state, value or ""))
            return
        per = (len(cells) + columns - 1) // columns
        for r in range(per):
            line = ""
            for c in range(columns):
                i = c * per + r
                if i < len(cells):
                    text, state = cells[i]
                    style = R.style_low if state != "active" else ""
                    line += ansi(text.ljust(width), style) if style else text.ljust(width)
            print(line.rstrip())


Warp()


# Registers absent from the current frame (x86 names on the GPU and vice versa)
# evaluate to void; report them as unavailable so the Registers module skips them.
_format_register = Registers.format_value


def _format_register_skip_void(value):
    if value.type.code == gdb.TYPE_CODE_VOID:
        return "<unavailable>"
    return _format_register(value)


Registers.format_value = staticmethod(_format_register_skip_void)


# pwndbg-style section titles: the label centered in brackets, "──[ CODE ]──".
_divider = divider


def divider(width, label="", primary=False, active=True):
    if not (label and primary):
        return _divider(width, label, primary, active)
    text = f"[ {label.upper()} ]"
    left = max((width - len(text)) // 2, 0)
    right = max(width - len(text) - left, 0)
    fill = R.divider_fill_char_primary
    label_style = R.divider_label_style_on_primary if active else R.divider_label_style_off_primary
    return (
        ansi(fill * left, R.divider_fill_style_primary)
        + ansi(text, label_style)
        + ansi(fill * right, R.divider_fill_style_primary)
    )


# On the GPU, draw the registers ourselves: every allocated R, the predicates,
# and the uniform files, with runs of zeros folded ("R40..R47 = 0", like
# cuda-gdb-plus) so 80+ registers fit on a few lines.
_registers_lines = Registers.lines


def _device_register_names(focus):
    dev = focus.device
    return [
        [f"R{i}" for i in range(focus.warp.registers_allocated)],
        [f"P{i}" for i in range(dev.num_predicates - 1)],
        [f"UR{i}" for i in range(dev.num_uregisters)],
        [f"UP{i}" for i in range(dev.num_upredicates - 1)],
    ]


def _fold(names, frame, table, min_run=3):
    """(label, value, changed) cells; runs of >= min_run zeros become one cell."""
    cells, run = [], []

    def flush():
        if len(run) >= min_run:
            cells.append((f"{run[0][0]}..{run[-1][0]}", "0", any(c for _, _, c in run)))
        else:
            cells.extend(run)
        run.clear()

    for name in names:
        try:
            value = Registers.format_value(frame.read_register(name))
        except gdb.error, ValueError:
            continue
        changed = bool(table) and table.get(name, value) != value
        table[name] = value
        if int(value, 16) == 0 if value.startswith("0x") else False:
            run.append((name, value, changed))
        else:
            flush()
            cells.append((name, value, changed))
    flush()
    return cells


def _grid(cells, term_width):
    """Column-major grid; every column is two aligned sub-columns: bold name, value.

    A changed register gets pwndbg's red '*' marker in a 1-char gutter, so names
    stay aligned whether or not they changed.
    """

    def widths(chunk):
        return max(len(n) for n, _, _ in chunk), max(len(v) for _, v, _ in chunk)

    gap = 3
    name_w, value_w = widths(cells)
    columns = max(1, (term_width - 1) // (1 + name_w + 1 + value_w + gap))
    rows = (len(cells) + columns - 1) // columns
    out = [""] * rows
    for c in range(0, len(cells), rows):
        chunk = cells[c : c + rows]
        name_w, value_w = widths(chunk)  # tighter per-column widths
        for r, (name, value, changed) in enumerate(chunk):
            mark = ansi("*", "1;" + C["red"]) if changed else " "
            label = ansi(name.ljust(name_w), "1;" + C["red"] if changed else "1")
            text = ansi(value.ljust(value_w), "1;" + C["red"]) if changed else value.ljust(value_w)
            out[r] += "{}{} {}{}".format(mark, label, text, " " * gap)
    return [line.rstrip() for line in out]


def _registers_lines_cuda(self, term_width, term_height, style_changed):
    focus = cuda_focus()
    if focus is None:
        return _registers_lines(self, term_width, term_height, style_changed)
    if style_changed:
        self.table = {}
    frame = gdb.selected_frame()
    out = [" {} {}".format(ansi("pc", "1"), Registers.format_value(frame.read_register("pc")))]
    for names in _device_register_names(focus):
        cells = _fold(names, frame, self.table)
        if cells:
            out.extend(_grid(cells, term_width))
    return out


Registers.lines = _registers_lines_cuda
