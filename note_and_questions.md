# Skynet Socket模块与原生Socket的区别

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
