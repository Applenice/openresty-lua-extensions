### access阶段请求鉴权和打点记录
1、安装openresty
```shell
wget https://openresty.org/package/centos/openresty.repo
mv openresty.repo /etc/yum.repos.d/openresty.repo
yum check-update
yum install openresty openresty-resty
```

2、配置一个下载location
```conf
location ^~ /filedownload/ {
    alias /opt/opsdata/filedownload/; 
    lua_code_cache on;  
    access_by_lua_file /usr/local/openresty/luacode/checksecret.lua;
}
```

3、openresty -s reload

4、启动redis和fastapi容器
