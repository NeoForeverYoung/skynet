--===== 集群模式示例(Ping服务) =====
-- 导入skynet核心库和集群模块
local skynet = require "skynet"
local cluster = require "skynet.cluster"

-- 获取当前节点的名称(通过环境变量)
local mynode = skynet.getenv("node")

-- 命令处理表，用于处理接收到的不同类型的消息
local CMD = {}

-- 处理接收到的ping消息
-- @param source: 消息发送者的服务地址
-- @param source_node: 发送者的节点名称
-- @param source_srv: 发送者的服务地址/名称
-- @param count: ping-pong的计数值
function CMD.ping(source, source_node, source_srv, count)
    -- 获取当前服务的地址
    local id = skynet.self()
    -- 输出日志，显示接收到的ping消息和计数
    skynet.error("["..id.."] recv ping count="..count)
    -- 休眠100个时间单位(10ms)，模拟处理延迟
    skynet.sleep(100)
    -- 通过集群发送ping消息给源服务，计数值加1
    -- 这里使用cluster.send而不是skynet.send，因为要跨节点通信
    cluster.send(source_node, source_srv, "ping", mynode, skynet.self(), count+1)
end

-- 启动ping-pong通信的处理函数
-- @param source: 消息发送者的服务地址
-- @param target_node: 目标节点名称
-- @param target: 目标服务的名称/地址
function CMD.start(source, target_node, target)
    -- 发送第一个ping消息给目标节点的目标服务，初始计数为1
    cluster.send(target_node, target, "ping", mynode, skynet.self(), 1)
end

-- skynet服务的入口函数
skynet.start(function()
    -- 注册lua类型消息的分发处理函数
    skynet.dispatch("lua", function(session, source, cmd, ...)
      -- 根据命令名查找对应的处理函数
      local f = assert(CMD[cmd])
      -- 调用处理函数，传入消息源和其他参数
      f(source, ...)
    end)
end)