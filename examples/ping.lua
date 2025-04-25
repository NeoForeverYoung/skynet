-- 引入skynet核心库，这是使用skynet框架的必要步骤
local skynet = require "skynet"

-- 定义命令表，用于处理接收到的不同类型的消息
local CMD = {}

-- start命令处理函数，当收到"start"命令时被调用
-- source: 消息发送方的服务句柄
-- target: 消息参数，这里是另一个ping服务的句柄
function CMD.start(source, target)
    -- 向target服务发送"ping"命令，携带参数1作为初始计数值
    -- 这将启动两个ping服务之间的通信
    skynet.send(target, "lua", "ping", 1)
end

-- ping命令处理函数，当收到"ping"命令时被调用
-- source: 消息发送方的服务句柄
-- count: 当前的计数值
function CMD.ping(source, count)
    -- 获取当前服务的句柄（ID）
    local id = skynet.self()
    -- 输出日志信息，显示当前服务ID和接收到的计数值
    skynet.error("["..id.."] recv ping count="..count)
    -- 暂停100毫秒，模拟处理时间
    skynet.sleep(100)
    -- 向消息发送方回复"ping"命令，计数值加1
    -- 这样两个服务会不断地互相发送ping消息，计数值不断增加
    skynet.send(source, "lua", "ping", count+1)
end


-- skynet.start是服务的入口函数，传入一个匿名函数作为服务的主体逻辑
skynet.start(function()
    -- 注册lua类型消息的分发处理函数
    -- 当服务收到lua类型的消息时，会调用这个函数来处理
    skynet.dispatch("lua", function(session, source, cmd, ...)
      -- 根据cmd查找对应的处理函数，如果不存在则触发错误
      local f = assert(CMD[cmd])
      -- 调用对应的处理函数，传入消息源和其他参数
      f(source,...)
    end)
end)