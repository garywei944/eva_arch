local naughty = require("naughty")
local gears = require("gears")

local logging = {}

-- ----------------------------
-- Log levels (Python style)
-- ----------------------------
logging.DEBUG = 10
logging.INFO = 20
logging.WARNING = 30
logging.ERROR = 40
logging.CRITICAL = 50

logging.level = logging.INFO

local level_names = {
    [logging.DEBUG] = "DEBUG",
    [logging.INFO] = "INFO",
    [logging.WARNING] = "WARNING",
    [logging.ERROR] = "ERROR",
    [logging.CRITICAL] = "CRITICAL",
}

-- ----------------------------
-- internal log function
-- ----------------------------
local function emit(level, name, msg)
    if level < logging.level then
        return
    end

    local ts = os.date("%m%d %H:%M:%S")

    local prefix = string.format("[%s][%s][%s] ", ts, level_names[level], name or "root")

    print(prefix .. tostring(msg))

    -- notification policy
    if level == logging.WARNING then
        naughty.notify({
            title = "Warning",
            text = msg,
            timeout = 4,
        })
    elseif level >= logging.ERROR then
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = level_names[level],
            text = msg,
        })
    end
end

-- ----------------------------
-- Logger object
-- ----------------------------
local function create_logger(name)
    local logger = {}

    function logger.debug(msg)
        emit(logging.DEBUG, name, msg)
    end

    function logger.info(msg)
        emit(logging.INFO, name, msg)
    end

    function logger.warning(msg)
        emit(logging.WARNING, name, msg)
    end

    function logger.error(msg)
        emit(logging.ERROR, name, msg)
    end

    function logger.critical(msg)
        emit(logging.CRITICAL, name, msg)
    end

    function logger.debug_table(tbl)
        local dump = gears.debug.dump_return(tbl)
        emit(logging.DEBUG, name, dump)
    end

    return logger
end

-- ----------------------------
-- public API
-- ----------------------------
function logging.set_level(level)
    logging.level = level
end

function logging.get_logger(name)
    return create_logger(name)
end

-- root logger
logging.root = create_logger("root")

-- ----------------------------
-- Awesome error hooks
-- ----------------------------
function logging.setup_error_handling()
    if awesome.startup_errors then
        logging.root.critical("Startup error: " .. awesome.startup_errors)
    end

    local in_error = false

    awesome.connect_signal("debug::error", function(err)
        if in_error then
            return
        end

        in_error = true
        logging.root.error(tostring(err))
        in_error = false
    end)
end

return logging
