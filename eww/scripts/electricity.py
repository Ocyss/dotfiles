#!/bin/env python3
# coding:utf-8
"""
Author: Ocyss qiudie@88.com
Date: 2023-07-13 18:50:24
"""
import requests
import json
import sys
import os
import time

path = os.path.split(os.path.realpath(__file__))[0]


def getHour():
    url = "http://112.124.53.89:8080/emdev/useInfo"
    url2 = "http://112.124.53.89:8080/em/emGroupList"
    headers = {
        "content-type": "application/json",
        "authorization": os.getenv("OCYSS_ElectricityAuthorization"),
    }
    data = {
        "uid": "278ef2d0-f098-462d-afce-ea87079eb7a9",
        "by": "hour",
        "date": time.strftime("%Y-%m-%d", time.localtime()),
    }
    res = requests.post(url, headers=headers, data=json.dumps(data)).json()
    res2 = requests.get(url2, headers=headers).json()
    # print(res, res2)
    if res["code"] == 0 and res2["code"] == 0:
        res["quantity"] = res2["data"]["data"]["UN海陆公社"][0]["quantity"]
        with open(
            path + "/temp/electricityBill.cache", mode="w", encoding="utf-8"
        ) as f:
            json.dump(res, f)
        return json.dumps(
            {
                "icon": "",
                "msg": "%.1f°" % sum(x["duringUsed"] for x in res["data"]),
                "iconColor": "#1E90FF" if res["quantity"] > 10 else "#FF0000",
                "msgColor": "#ffffff",
            }
        )
    else:
        return json.dumps(
            {"icon": "", "msg": "reqE", "iconColor": "#FF0000", "msgColor": "#ffffff"}
        )


try:
    match sys.argv[1]:
        case "module":
            print(getHour())
        case "click":
            content = ""
            with open(path + "/temp/electricityBill.cache", "r", encoding="utf-8") as f:
                res = json.load(f)
                su = sum(x["duringUsed"] for x in res["data"])
                content = (
                    f'<span font_size="17pt">\
电量：%.2f 度\n\
电费：%.2f 元\n\
剩余: %.2f 度</span>\n'
                    % (su, su * 0.8, res["quantity"])
                )
                for r in res["data"]:
                    t = time.strptime(r["createTime"], "%Y-%m-%dT%H:%M:%S")
                    content += '<span font_size="16pt">%s</span>---%.2f\n' % (
                        time.strftime("%H:%M:%S", t),
                        r["duringUsed"],
                    )

                n = f"dunstify -t 15000 -i none  \
        '\t今日电量' '{content}'"
                print(n)
                os.system(n)
except BaseException as e:
    print(
        json.dumps(
            {"icon": "", "msg": "reqE", "iconColor": "#FF0000", "msgColor": "#ffffff"}
        )
    )
