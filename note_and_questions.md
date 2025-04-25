# Skynet Socket模块与原生Socket的区别
- SkyNet本质上是一个单进程多线程的服务器框架，使用Actor模式来避免业务逻辑在多线程之间加锁。
## 主要区别

### 1. 协程化处理
- skynet的socket API是基于协程设计的，可以非阻塞地执行I/O操作
- 当socket.read()无数据可读时，会自动挂起当前协程，而不是阻塞整个服务
- 当数据到达时，skynet会自动唤醒协程继续执行，这使得编程模型更简单

### 2. 事件驱动集成
- skynet的socket模块与skynet自身的事件驱动系统完全集成
- 底层使用epoll/kqueue等高效的I/O复用机制
- 对开发者隐藏了复杂的事件回调设计

### 3. 服务模型融合
- 原生socket需要自己处理多线程/多进程模型
- skynet的socket天然融入了skynet的服务模型
- 每个服务可以处理多个连接，而不必担心线程同步问题

### 4. 简化的API
- skynet.socket提供了更简洁的API，如：
  - `socket.listen()` - 创建监听socket
  - `socket.start()` - 启动socket或设置连接回调
  - `socket.read()` - 读取数据（看似阻塞但实际是协程挂起）
  - `socket.write()` - 发送数据

### 5. 内部优化
- 内部实现了高效的读写缓冲区
- 自动处理TCP粘包问题
- 提供了各种数据打包解包的辅助函数

## 代码对比示例

**原生socket实现（伪代码）**：
```lua
-- 需要手动处理非阻塞、多线程等问题
local server = socket.create()
socket.bind(server, "0.0.0.0", 8888)
socket.listen(server, 5)
-- 需要复杂的多线程/事件循环来处理并发
while true do
    local client = socket.accept(server)
    -- 创建新线程处理客户端
    create_thread(function()
        while true do
            local data = socket.recv(client) -- 这里会阻塞线程
            if not data then break end
            socket.send(client, data)
        end
    end)
end
```

**skynet socket实现**：
```lua
-- 代码更简洁，天然支持并发
local listenfd = socket.listen("0.0.0.0", 8888)
socket.start(listenfd, function(fd, addr)
    socket.start(fd)
    while true do
        local data = socket.read(fd) -- 协程会自动挂起，不会阻塞服务
        if not data then break end
        socket.write(fd, data)
    end
end)
```

## 总结

skynet的socket是对原生socket的高级封装，它整合了skynet的协程和事件驱动系统，使网络编程变得更简单、更高效，开发者可以用看似同步的代码实现异步的高并发网络应用。

# Skynet集群配置与启动问题

## 集群配置示例

以下是集群模式的主程序示例:

```lua
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
```

## 端口监听问题分析

运行`./skynet examples/Pconfig.c1`时出现错误：
```
[:01000004] init service failed: ./lualib/skynet/socket.lua:414: Listen error
```

### 错误原因：

1. 配置文件`Pconfig.c1`中设置了`standalone = "0.0.0.0:2013"`和`master = "127.0.0.1:2013"`
2. skynet尝试在0.0.0.0:2013端口上启动监听，但失败了
3. 可能的原因：
   - 端口2013已被其他程序占用
   - 权限问题（某些系统中低于1024的端口需要root权限）
   - 网络配置问题

### 解决方案：

1. **更换端口**：修改配置文件中的端口为未使用的端口
   ```
   standalone = "0.0.0.0:2013" --> standalone = "0.0.0.0:2399"
   master = "127.0.0.1:2013" --> master = "127.0.0.1:2399"
   ```

2. **检查端口占用**：可以运行以下命令查看端口是否被占用
   ```bash
   lsof -i :2013
   ```

3. **检查防火墙设置**：确保防火墙允许该端口的访问

4. **重启计算机**：有时候重启可以释放被占用但未正确释放的端口
