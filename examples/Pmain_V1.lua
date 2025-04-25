-- 引入skynet核心库，这是使用skynet框架的必要步骤
local skynet = require "skynet"

-- skynet.start是服务的入口函数，传入一个匿名函数作为服务的主体逻辑
skynet.start(function()
    -- 输出日志信息，表明Pmain服务已经启动
    skynet.error("[Pmain] start")
    -- 创建第一个ping服务实例，返回服务句柄存储在ping1变量中
    local ping1 = skynet.newservice("ping")
    -- 创建第二个ping服务实例，返回服务句柄存储在ping2变量中
    local ping2 = skynet.newservice("ping")
    
    -- 向ping1服务发送消息，类型为"lua"，命令为"start"，参数为ping2服务的句柄
    -- 该消息会触发ping1服务中的CMD.start函数，开始ping服务之间的通信
    skynet.send(ping1, "lua", "start", ping2)
    -- 退出当前Pmain服务，注意这不会导致整个skynet应用程序退出，只是结束当前这个服务
    skynet.exit()
end)