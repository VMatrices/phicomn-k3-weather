# phicomn-k3-weather
用于斐讯K3 [k3screenctrl]([](https://github.com/lwz322/k3screenctrl)) 的天气更新脚本





## 简介

重构自带脚本，改进并新增了以下特性：

- 支持显示错误信息，方便定位
- LuCI配置更新后立即刷新
- 网络错误30秒后自动重试
- 天气信息及IP定位仅使用彩云API




![Screen](/preview.png)




## 安装

ssh登录路由器，执行以下命令：

```shell
wget https://raw.githubusercontent.com/VMatrices/phicomn-k3-weather/main/weather.sh -O /lib/k3screenctrl/weather.sh
```





## 关联

[https://github.com/lwz322/k3screenctrl](https://github.com/lwz322/k3screenctrl)

[https://github.com/zxlhhyccc/Hill-98-k3screenctrl](https://github.com/zxlhhyccc/Hill-98-k3screenctrl)

[https://github.com/updateing/k3screenctrl](https://github.com/updateing/k3screenctrl)



