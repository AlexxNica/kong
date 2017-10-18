-- Copyright (C) Kong Inc.

local BasePlugin = require "kong.plugins.base_plugin"

local math_random = math.random
local math_floor = math.floor
local math_fmod = math.fmod
local crc32 = ngx.crc32_short

local Canary = BasePlugin:extend()

function Canary:new()
  Canary.super.new(self, "canary")
end

local function get_hash_input()
  local ctx = ngx.ctx
  -- Consumer is identified id
  local identifier = ctx.authenticated_consumer and ctx.authenticated_consumer.id
  if not identifier and ctx.authenticated_credential then
    -- Fallback on credential
    identifier = ctx.authenticated_credential.id
    if not identifier then
      -- Fallback on remote IP
      identifier = ngx.var.remote_addr
      if not identifier then
        -- Fallback on a random number
        identifier = tostring(math_random())
      end
    end
  end
  return identifier
end

function Canary:access(conf)
  Canary.super.access(self)
  
  local start, steps, duration = conf.start, conf.steps, conf.duration
  local time = ngx.now()
  if time < start then
    -- not started yet, exit
    return
  end

  if time > start + duration then
    -- completely done, switch target
    ngx.balancer_address.host = conf.hostname_b
    return
  end

  -- calculate current step, and hash position. Both 0-indexed.
  local step = math_floor((time - start) / duration * steps)
  local hash = math_fmod(crc32(get_hash_input()), steps)

  if hash <= step then
    -- switch upstream host to the new hostname
    ngx.balancer_address.host = conf.hostname_b
  end
end

Canary.PRIORITY = 13

return Canary
