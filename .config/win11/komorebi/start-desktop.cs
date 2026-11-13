// Logon entry point, run by the komorebi.lnk Startup shortcut: starts the
// kanata task, then komorebi, whkd, masir and YASB, and shows a small notice in
// the bottom-right corner meanwhile. install.sh builds it with the .NET
// Framework csc.exe that ships with Windows. Its name must not contain
// "komorebi.exe": komorebi finds other instances of itself by a substring match
// on process names and exits when it sees one.
//
// komorebi exits at once with "failed call to AllowSetForegroundWindow" unless
// the process that starts it may set the foreground window. A process started
// by Explorer from the Startup folder only may if Explorer is still in the
// foreground when the Startup items run, so clicking into any window early in a
// logon used to leave komorebi down. This program takes the foreground for its
// own notice first (attaching to the foreground thread's input, or, failing
// that, a synthetic Alt press), so the komorebi it starts inherits the right,
// and it takes the foreground again before every retry. The previous foreground
// window gets it back once komorebi answers. Neither trick works while the
// screen is locked or an elevated window has the focus, and the desktop may
// stay locked for hours after a reboot, so retries back off exponentially
// (from 1 s, 1.1 times longer each try, at most 30 s) and never give up.
//
// While the notice holds the foreground, keys typed for another window land on
// it. It therefore has no system menu (after the synthetic Alt, a typed "c"
// would pick its Close item) and refuses to close (Alt+F4) before komorebi
// answers; either used to end this process, startup thread included, without
// a trace. A close only dismisses the notice until then.
//
// Every program runs without a console window (CREATE_NO_WINDOW). komorebi's
// stderr, which only carries panics, goes to
// %LOCALAPPDATA%\komorebi\komorebi.err. This program logs its own progress to
// start-desktop.log next to it: komorebi keeps komorebi.err open and lets
// nobody else write to it while it runs.
using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Text;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

static class Program {
  [DllImport("user32.dll")]
  static extern bool SetProcessDpiAwarenessContext(IntPtr value);

  [STAThread]
  static void Main() {
    SetProcessDpiAwarenessContext(new IntPtr(-4)); // per-monitor v2: crisp text
    var notice = new Notice();
    notice.Shown += delegate {
      new Thread(() => Startup.Run(notice)) { IsBackground = true }.Start();
    };
    Application.Run(notice);
  }
}

static class Startup {
  static readonly string LogDir = Path.Combine(
      Environment.GetEnvironmentVariable("LOCALAPPDATA"), "komorebi");
  static readonly string ErrLog = Path.Combine(LogDir, "komorebi.err");
  static readonly string OwnLog = Path.Combine(LogDir, "start-desktop.log");

  public static void Run(Notice notice) {
    Log("starting the desktop");
    // kanata carries the keyboard layout, so it starts first, without waiting
    // for komorebi.
    Spawn("schtasks.exe", "/run /tn kanata");

    bool up = KomorebiAnswers();
    int attempt = 0, delayMs = 1000;
    while (!up) {
      if (!(bool)notice.Invoke(new Func<bool>(notice.TakeForeground))) {
        // The lock screen or an elevated foreground window refuses both
        // tricks; wait until it goes away.
        notice.Show(Notice.State.Waiting);
        Log("no foreground rights yet, next try in " + Seconds(delayMs));
      } else {
        notice.Show(Notice.State.Starting);
        attempt++;
        // `start /b` lets cmd exit while komorebi keeps the redirected handles.
        // Its log on stdout goes to nul; komorebi also writes it to
        // %TEMP%\komorebi_plaintext.log.*.
        Spawn("cmd.exe",
              "/d /c start \"\" /b komorebi.exe >nul 2>>\"" + ErrLog + "\"");
        for (int i = 0; i < 20 && !up; i++) {
          Thread.Sleep(250);
          up = KomorebiAnswers();
        }
        if (up)
          break;
        Log("komorebi did not start, attempt " + attempt + ", next try in " +
            Seconds(delayMs));
      }
      Thread.Sleep(delayMs);
      delayMs = Math.Min(delayMs * 11 / 10, 30000);
    }
    notice.Invoke(new Action(notice.RestoreForeground));

    // Skip what already runs, so that launching this again by hand does not
    // double anything.
    if (!Running("whkd"))
      Spawn("whkd.exe", "");
    if (!Running("masir"))
      Spawn("masir.exe", "");
    if (!Running("yasb"))
      Spawn(Path.Combine(Environment.GetEnvironmentVariable("ProgramFiles"),
                         "YASB", "yasb.exe"),
            "");
    Log("komorebi answers after " + attempt + " attempt(s), desktop ready");
    notice.Show(Notice.State.Ready);
  }

  static string Seconds(int ms) { return (ms / 1000.0).ToString("0.0") + " s"; }

  static bool KomorebiAnswers() {
    var info = new ProcessStartInfo("komorebic.exe", "state") {
      UseShellExecute = false,
      CreateNoWindow = true,
      RedirectStandardOutput = true,
      RedirectStandardError = true,
    };
    try {
      using (var p = Process.Start(info)) {
        p.StandardError.ReadToEndAsync();
        p.StandardOutput.ReadToEnd();
        p.WaitForExit();
        return p.ExitCode == 0;
      }
    } catch (Exception) {
      return false;
    }
  }

  static bool Running(string name) {
    return Process.GetProcessesByName(name).Length > 0;
  }

  static void Spawn(string file, string args) {
    var info = new ProcessStartInfo(file, args) { UseShellExecute = false,
                                                  CreateNoWindow = true };
    try {
      Process.Start(info).Dispose();
    } catch (Exception e) {
      Log("cannot start " + file + ": " + e.Message);
    }
  }

  static void Log(string line) {
    try {
      File.AppendAllText(OwnLog,
                         DateTime.Now.ToString("MM/dd/yyyy ddd H:mm:ss.ff") +
                             " " + line + "\r\n");
    } catch (IOException) {
    }
  }
}

// A borderless, rounded tool window in the bottom-right corner of the primary
// monitor, styled like the YASB bar. Tool windows are not tiled by komorebi.
// Click it to close it early.
class Notice : Form {
  public enum State { Starting, Waiting, Ready }

  [DllImport("user32.dll")]
  static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")]
  static extern bool SetForegroundWindow(IntPtr hwnd);
  [DllImport("user32.dll")]
  static extern bool IsWindow(IntPtr hwnd);
  [DllImport("user32.dll")]
  static extern uint GetWindowThreadProcessId(IntPtr hwnd, IntPtr pid);
  [DllImport("kernel32.dll")]
  static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")]
  static extern bool AttachThreadInput(uint from, uint to, bool attach);
  [DllImport("user32.dll")]
  static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  [DllImport("user32.dll")]
  static extern uint GetDpiForWindow(IntPtr hwnd);
  [DllImport("dwmapi.dll")]
  static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value,
                                          int size);

  static readonly Color Background = Color.FromArgb(0x18, 0x1d, 0x24);
  static readonly Color Border = Color.FromArgb(0x35, 0x3b, 0x44);
  static readonly Color Text1 = Color.FromArgb(0xe6, 0xe8, 0xec);
  static readonly Color Text2 = Color.FromArgb(0x9a, 0xa1, 0xab);
  static readonly Color Accent = Color.FromArgb(0xa2, 0xc9, 0xfd);
  static readonly Color Good = Color.FromArgb(0x9f, 0xd8, 0xa0);
  const int ReadyMs = 5000, TickMs = 16;

  State state = State.Starting;
  IntPtr previous;
  float scale = 1, spin, opacity;
  int readyLeft = ReadyMs;
  bool closing;
  Font titleFont, bodyFont, iconFont;
  readonly System.Windows.Forms.Timer timer =
      new System.Windows.Forms.Timer { Interval = TickMs };

  public Notice() {
    FormBorderStyle = FormBorderStyle.None;
    ControlBox = false; // no system menu, see the top of this file
    ShowInTaskbar = false;
    TopMost = true;
    StartPosition = FormStartPosition.Manual;
    BackColor = Background;
    Opacity = 0;
    DoubleBuffered = true;
    timer.Tick += delegate { Tick(); };
    Click += delegate { closing = true; };
  }

  protected override bool ShowWithoutActivation {
    get { return true; }
  }

  protected override CreateParams CreateParams {
    get {
      var cp = base.CreateParams;
      cp.ExStyle |= 0x80; // WS_EX_TOOLWINDOW
      return cp;
    }
  }

  // Closing the only form ends the process, so a close before komorebi answers
  // only dismisses the notice. Our own Close() comes once it is Ready.
  protected override void OnFormClosing(FormClosingEventArgs e) {
    if (state != State.Ready && e.CloseReason == CloseReason.UserClosing) {
      e.Cancel = true;
      closing = true;
    }
    base.OnFormClosing(e);
  }

  protected override void OnHandleCreated(EventArgs e) {
    base.OnHandleCreated(e);
    int round = 2; // DWMWCP_ROUND
    DwmSetWindowAttribute(Handle, 33, ref round, 4);
    int border = ColorTranslator.ToWin32(Border); // DWMWA_BORDER_COLOR
    DwmSetWindowAttribute(Handle, 34, ref border, 4);
    scale = GetDpiForWindow(Handle) / 96f;
    titleFont = new Font("Microsoft YaHei UI", 14 * scale, FontStyle.Bold,
                         GraphicsUnit.Pixel);
    bodyFont = new Font("Microsoft YaHei UI", 12 * scale, GraphicsUnit.Pixel);
    iconFont = new Font("Segoe Fluent Icons", 18 * scale, GraphicsUnit.Pixel);
    Size size = new Size((int)(340 * scale), (int)(76 * scale));
    Rectangle area = Screen.PrimaryScreen.WorkingArea;
    int margin = (int)(16 * scale);
    Bounds = new Rectangle(area.Right - size.Width - margin,
                           area.Bottom - size.Height - margin, size.Width,
                           size.Height);
    timer.Start();
  }

  // Called on the UI thread. Makes this notice the foreground window, so that
  // processes started now may set the foreground window too.
  public bool TakeForeground() {
    IntPtr fg = GetForegroundWindow();
    if (fg == Handle)
      return true;
    if (previous == IntPtr.Zero)
      previous = fg;
    uint me = GetCurrentThreadId();
    uint other =
        fg == IntPtr.Zero ? 0 : GetWindowThreadProcessId(fg, IntPtr.Zero);
    bool attached =
        other != 0 && other != me && AttachThreadInput(me, other, true);
    SetForegroundWindow(Handle);
    if (attached)
      AttachThreadInput(me, other, false);
    if (GetForegroundWindow() == Handle)
      return true;
    // A key event unlocks SetForegroundWindow; the Alt release then goes to
    // this notice.
    const byte VkMenu = 0x12;
    keybd_event(VkMenu, 0, 0, UIntPtr.Zero);
    SetForegroundWindow(Handle);
    keybd_event(VkMenu, 0, 2, UIntPtr.Zero); // KEYEVENTF_KEYUP
    return GetForegroundWindow() == Handle;
  }

  public void RestoreForeground() {
    if (GetForegroundWindow() == Handle && previous != IntPtr.Zero &&
        IsWindow(previous))
      SetForegroundWindow(previous);
  }

  public void Show(State next) {
    BeginInvoke(new Action(() => {
      state = next;
      if (closing && next == State.Ready)
        Close(); // already dismissed by a click
      else
        Invalidate();
    }));
  }

  void Tick() {
    spin = (spin + 6) % 360;
    if (state == State.Ready && !closing) {
      readyLeft -= TickMs;
      if (readyLeft <= 0)
        closing = true;
    }
    float target = closing ? 0 : 0.97f;
    opacity += Math.Sign(target - opacity) *
               Math.Min(Math.Abs(target - opacity), 0.08f);
    Opacity = opacity;
    if (closing && opacity <= 0) {
      timer.Stop();
      // Keep the process (and the startup thread) alive until the work is done.
      if (state == State.Ready)
        Close();
      else
        Hide();
      return;
    }
    Invalidate();
  }

  protected override void OnPaint(PaintEventArgs e) {
    if (closing && !Visible)
      return;
    Graphics g = e.Graphics;
    g.SmoothingMode = SmoothingMode.AntiAlias;
    g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;

    string title, body, glyph = null;
    Color color;
    switch (state) {
    case State.Waiting:
      title = "正在等待前台权限";
      body = "请解锁，或切到一个普通（非管理员）窗口";
      color = Accent;
      break;
    case State.Ready:
      title = "桌面已就绪";
      body = "komorebi · whkd · YASB · kanata 已启动";
      color = Good;
      glyph = "\uE930"; // Completed
      break;
    default:
      title = "正在启动 komorebi";
      body = "完成前请先别动键盘和鼠标";
      color = Accent;
      break;
    }

    float pad = 18 * scale, icon = 22 * scale;
    var iconBox = new RectangleF(pad, (Height - icon) / 2, icon, icon);
    if (glyph == null) {
      using (var track = new Pen(Border, 2.5f * scale)) using (
          var arc = new Pen(color, 2.5f * scale) { StartCap = LineCap.Round,
                                                   EndCap = LineCap.Round }) {
        g.DrawEllipse(track, iconBox);
        g.DrawArc(arc, iconBox, spin, 100);
      }
    } else {
      TextRenderer.DrawText(g, glyph, iconFont, Rectangle.Round(iconBox), color,
                            TextFormatFlags.HorizontalCenter |
                                TextFormatFlags.VerticalCenter);
    }

    int textX = (int)(pad + icon + 14 * scale);
    TextRenderer.DrawText(g, title, titleFont,
                          new Point(textX, (int)(17 * scale)), Text1,
                          Background);
    TextRenderer.DrawText(g, body, bodyFont,
                          new Point(textX, (int)(41 * scale)), Text2,
                          Background);

    // Ready: a thin bar along the bottom counts down to when the notice
    // disappears.
    if (state == State.Ready) {
      float width = (Width - 2 * pad) * Math.Max(readyLeft, 0) / ReadyMs;
      using (var bar = new SolidBrush(Color.FromArgb(160, color)))
          g.FillRectangle(bar, pad, Height - 5 * scale, width, 2 * scale);
    }
  }
}
