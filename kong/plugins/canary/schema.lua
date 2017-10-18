local utils = require "kong.tools.utils"
local Errors = require "kong.dao.errors"

return {
  no_consumer = true,
  fields = {
    start = {       -- when to start the release (seconds since epoch)
      type = "number",
    },
    duration = {    -- how long should the transtion take (seconds)
      type = "number",
      default = 60 * 60  -- 1 hour
    },
    steps = {       -- how many steps
      type = "number",
      default = 1000,
    },
    hostname_b = {  -- target hostname (upstream_url == a, this is b)_
      type = "string",
    },
  },
  self_check = function(schema, conf, dao, is_update)
    -- validate start time
    local time = ngx.time()
    if not conf.start then
      conf.start = time
    end
    if conf.start < time then
      return false, Errors.schema "'start' cannot be in the past"
    end

    -- validate duration
    if conf.duration <= 0 then
      return false, Errors.schema "'duration' must be greater than 0"
    end

    -- validate steps
    if conf.steps <= 0 then
      return false, Errors.schema "'steps' must be greater than 0"
    end

    -- validate hostname
    if not utils.check_hostname(conf.hostname_b) then
      return false, Errors.schema "'hostname_b' must be a valid hostname"
    end
  end,
}
