--===== 集群模式示例(主程序) =====
-- 导入skynet核心库、集群模块和管理模块
local skynet = require "skynet"
local cluster = require "skynet.cluster"
require "skynet.manager"  -- 用于支持skynet.name函数
 
-- skynet服务的入口函数
skynet.start(function()
    -- 配置集群节点信息，设置各节点的地址和端口
    cluster.reload({
        node1 = "127.0.0.1:7001",  -- 节点1地址
        node2 = "127.0.0.1:7002"   -- 节点2地址
    })
    
    -- 获取当前节点的名称(通过环境变量)
    local mynode = skynet.getenv("node")

    -- 根据节点名称执行不同逻辑
    if mynode == "node1" then
        -- 节点1: 打开集群通信端口
        cluster.open("node1")
        
        -- 创建两个ping服务实例
        local ping1 = skynet.newservice("ping")
        local ping2 = skynet.newservice("ping")
        
        -- 向两个ping服务发送启动命令，让它们与node2上的pong服务通信
        skynet.send(ping1, "lua", "start", "node2", "pong")
        skynet.send(ping2, "lua", "start", "node2", "pong")
    elseif mynode == "node2" then
        -- 节点2: 打开集群通信端口
        cluster.open("node2")
        
        -- 创建一个ping服务实例
        local ping3 = skynet.newservice("ping")
        
        -- 将该服务命名为"pong"，使得其他节点可以通过名字访问
        skynet.name("pong", ping3)
    end
end)