#!/bin/bash
. /lib/network/config.sh
. /lib/functions.sh

weather_time_path=/tmp/k3_weather_time
weather_json_path=/tmp/k3_weather_json
weather_conf_path=/tmp/k3_weather_conf

# https://docs.seniverse.com/api/start/error.html
declare -A api_error_map=(
	['AP010002']='No Permission'
	['AP010003']='Invalid API Key'
	['AP010006']='City Inaccessible'
	['AP010010']='City Not Found'
	['AP010011']='Cannot Locate City'
	['AP010012']='Service Expired'
	['AP010013']='Access Count Not enough'
	['AP010014']='Access Too quickly'
	['AP100001']='Missing Data'
	['AP100002']='Data Errors'
	['AP100003']='Service Error'
	['AP100004']='Gateway Error'
)

# 显示天气: city, temperature, type
show_weather()
{
	date_week=$(date "+%u")
	if [ "$date_week" == "7" ]; then
		date_week=0
	fi
	echo "$1"
	echo "$2"
	date "+%Y-%m-%d"
	date "+%H:%M"
	echo "$3"
	echo "$date_week"
	echo 0
	exit
}

# 显示错误: msg
show_error()
{
	show_weather "$1" "" 99
}

# 读取更新间隔
update_interval=$(uci get k3screenctrl.@general[0].update_time 2>/dev/null)
if [ "$update_interval" = "0" ]; then
	show_error "(Disabled)"
fi

# 读取私钥
api_key=$(uci get k3screenctrl.@general[0].key 2>/dev/null)
if [ -z "$api_key" ]; then
	show_error "(Please set API Key)"
fi

# 读取城市
city_checkip=$(uci get k3screenctrl.@general[0].city_checkip 2>/dev/null)
if [ "$city_checkip" = "1" ]; then
	city=ip
else
	city=$(uci get k3screenctrl.@general[0].city 2>/dev/null)
	if [ -z "$city" ]; then
		show_error "(Please set city)"
	fi
fi

# 检查配置变化
conf_changed=0
current_conf="$update_interval $api_key $city_checkip $city"
last_conf=$(cat $weather_conf_path 2>/dev/null)
if [ "$current_conf" != "$last_conf" ]; then
	echo "$current_conf" > $weather_conf_path
	conf_changed=1
fi

# 检查更新时间
time_arrived=0
next_time=$(cat $weather_time_path 2>/dev/null)
if [ -z "$next_time" ] || [ "$(date +%s)" -ge "$next_time" ]; then
	time_arrived=1
fi

# 如果时间已到或者配置发生变化
weather_json=$(cat $weather_json_path 2>/dev/null)
if [[ "$time_arrived" = "1" || "$conf_changed" = "1" ]]; then
	rm -f /tmp/k3-weather.json
	weather_json=$(curl --connect-timeout 3 -s "http://api.seniverse.com/v3/weather/now.json?key=$api_key&location=$city&language=zh-Hans&unit=c")
	echo "$weather_json" > $weather_json_path
	# 设置下次更新时间
	expr "$(date +%s)" + "$update_interval" > $weather_time_path
fi

# 解析数据
if [ -n "$weather_json" ]; then

	# 判断响应是否正确
	error_status=$(echo "$weather_json" | jsonfilter -e '@.status')
	if [ -n "$error_status" ]; then
		error_msg=${api_error_map[$(echo "$weather_json" | jsonfilter -e '@.status_code')]}
		if [ -n "$error_msg" ]; then
			show_error "$error_msg"
		elif [ -n "$error_status" ]; then
			show_error "$error_status"
		fi
	fi
	
	# 获取实际地理位置
	real_city=$(echo "$weather_json" | jsonfilter -e '@.results[0].location.name')
	if [ -n "$real_city" ]; then
		uci set k3screenctrl.@general[0].city="$real_city"
		uci commit k3screenctrl
	fi

	temperature=$(echo "$weather_json" | jsonfilter -e '@.results[0].now.temperature')
	wather_type=$(echo "$weather_json" | jsonfilter -e '@.results[0].now.code')
	show_weather "$real_city" "$temperature" "$wather_type"
else
	show_error "Network Error"
	# 30秒后重新尝试
	expr "$(date +%s)" + 30 > $weather_time_path
fi
