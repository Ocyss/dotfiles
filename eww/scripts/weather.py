#!/bin/env python3
# coding:utf-8
"""
Author: Ocyss qiudie@88.com
Date: 2023-07-12 10:50:24
"""
import requests
import sys
import os
import json
import time
import datetime
import traceback

# 和风天气Api
# https://dev.qweather.com/docs/
PrivateKEY = os.getenv("Ocyss_WeatherPrivateKEY")
# 地区经纬度
location = "120.05,30.23"
path = os.path.split(os.path.realpath(__file__))[0]


def getIcon(id):
    # 图标库：https://github.com/qwd/Icons
    d = {
        "100": ["\uf1cc", "晴"],
        "101": ["\uf1cd", "多云"],
        "102": ["\uf1ce", "少云"],
        "103": ["\uf1cf", "晴间多云"],
        "104": ["\uf1d0", "阴"],
        "150": ["\uf1d1", "晴"],
        "151": ["\uf1d2", "多云"],
        "152": ["\uf1d3", "少云"],
        "153": ["\uf1d4", "晴间多云"],
        "300": ["\uf1d5", "阵雨"],
        "301": ["\uf1d6", "强阵雨"],
        "302": ["\uf1d7", "雷阵雨"],
        "303": ["\uf1d8", "强雷阵雨"],
        "304": ["\uf1d9", "雷阵雨伴有冰雹"],
        "305": ["\uf1da", "小雨"],
        "306": ["\uf1db", "中雨"],
        "307": ["\uf1dc", "大雨"],
        "308": ["\uf1dd", "极端降雨"],
        "309": ["\uf1de", "毛毛雨/细雨"],
        "310": ["\uf1df", "暴雨"],
        "311": ["\uf1e0", "大暴雨"],
        "312": ["\uf1e1", "特大暴雨"],
        "313": ["\uf1e2", "冻雨"],
        "314": ["\uf1e3", "小到中雨"],
        "315": ["\uf1e4", "中到大雨"],
        "316": ["\uf1e5", "大到暴雨"],
        "317": ["\uf1e6", "暴雨到大暴雨"],
        "318": ["\uf1e7", "大暴雨到特大暴雨"],
        "350": ["\uf1e8", "阵雨"],
        "351": ["\uf1e9", "强阵雨"],
        "399": ["\uf1ea", "雨"],
        "400": ["\uf1eb", "小雪"],
        "401": ["\uf1ec", "中雪"],
        "402": ["\uf1ed", "大雪"],
        "403": ["\uf1ee", "暴雪"],
        "404": ["\uf1ef", "雨夹雪"],
        "405": ["\uf1f0", "雨雪天气"],
        "406": ["\uf1f1", "阵雨夹雪"],
        "407": ["\uf1f2", "阵雪"],
        "408": ["\uf1f3", "小到中雪"],
        "409": ["\uf1f4", "中到大雪"],
        "410": ["\uf1f5", "大到暴雪"],
        "456": ["\uf1f6", "阵雨夹雪"],
        "457": ["\uf1f7", "阵雪"],
        "499": ["\uf1f8", "雪"],
        "500": ["\uf1f9", "薄雾"],
        "501": ["\uf1fa", "雾"],
        "502": ["\uf1fb", "霾"],
        "503": ["\uf1fc", "扬沙"],
        "504": ["\uf1fd", "浮尘"],
        "507": ["\uf1fe", "沙尘暴"],
        "508": ["\uf1ff", "强沙尘暴"],
        "509": ["\uf200", "浓雾"],
        "510": ["\uf201", "强浓雾"],
        "511": ["\uf202", "中度霾"],
        "512": ["\uf203", "重度霾"],
        "513": ["\uf204", "严重霾"],
        "514": ["\uf205", "大雾"],
        "515": ["\uf206", "特强浓雾"],
        "900": ["\uf144", "热"],
        "901": ["\uf208", "冷"],
        "999": ["\uf146", "未知"],
    }
    if id not in d:
        id = "999"
    return d[id][0] if len(d[id][0]) != 0 else d[id][1]


def getWeatherNow():
    bashUrl = "https://devapi.qweather.com/v7"
    weatherNow = f"{bashUrl}/weather/now?location={location}&key={PrivateKEY}"
    res = requests.get(weatherNow)
    if res.status_code != 200:
        return
    res = res.json()
    if res["code"] != "200":
        return
    # print(res)
    now = res["now"]
    with open(path + "/temp/weather.cache", mode="w", encoding="utf-8") as f:
        json.dump(now, f)
    return now


try:
    match sys.argv[1]:
        case "module":
            now = getWeatherNow()
            feels = now["feelsLike"]
            print(
                json.dumps(
                    {
                        "icon": getIcon(now["icon"]),
                        "msg": feels + "°",
                        "iconColor": "#B9C244",
                        "msgColor": "#ffffff",
                    }
                )
            )
        case "click":
            content = ""
            with open(path + "/temp/weather.cache", "r", encoding="utf-8") as f:
                now = json.load(f)
                t = datetime.datetime.strptime(
                    now["obsTime"], "%Y-%m-%dT%H:%M%z"
                ).replace(tzinfo=None)
                tt = datetime.datetime.now()

                content = f"<span font_size=\"17pt\">\
    <span font_desc=\"qweather\\-icons\">{getIcon(now['icon'])}</span>\
    {now['text']}\n\
    温度:{now['temp']}°C\n\
    体感:{now['feelsLike']}°C\n\
    湿度:{now['humidity']}%\n\
    风速:{now['windSpeed']}V</span>\n\
    <span font_size=\"12pt\">{int((tt-t).seconds/60)}分钟前</span>"

            n = f"dunstify -t 15000 -i none  \
    '天气预报' '{content}'"
            print(n)
            os.system(n)
except BaseException:
    print(
        json.dumps(
            {"icon": "-", "msg": "E", "iconColor": "#ff0000", "msgColor": "#ffffff"}
        )
    )
