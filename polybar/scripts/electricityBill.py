#!/bin/env python3
# coding:utf-8
'''
Author: Ocyss qiudie@88.com
Date: 2023-07-13 18:50:24
'''
import requests,json,sys,os,time

path = os.path.split(os.path.realpath(__file__))[0]

def getHour():
    url = "http://112.124.53.89:8080/emdev/useInfo"
    url2 = "http://112.124.53.89:8080/em/emGroupList"
    headers = {
        "content-type":"application/json",
        "authorization":"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJiM2U5MmY1OC1iMmI5LTQ3NjYtOTM5NC04OGU5OWIwNjJmM2MiLCJleHAiOjE2OTQ1Mjk2MTYsImp0aSI6IjVkNDVmNDUzLWZmOWMtNGI0OS04NDgyLTA1NTJhMjg0YTJmZCJ9.jhR4_-vdmO78YosrHvHsKE6syzq29w6VAMCeI7HTLV0"
    }
    data = {
        "uid": "278ef2d0-f098-462d-afce-ea87079eb7a9",
        "by": "hour",
        "date":time.strftime('%Y-%m-%d', time.localtime())
    }
    res = requests.post(url,headers=headers,data=json.dumps(data)).json()
    res2 = requests.get(url2,headers=headers).json()
    if res['code']==0 and res2['code']==0:
        res['quantity'] = res2['data']['data']['UN海陆公社'][0]['quantity']
        with open(path + "/electricityBill.cache", mode="w", encoding="utf-8") as f:
            json.dump(res, f)
        return "%.1f°" % sum(x['duringUsed'] for x in res["data"])
    else:
        print(res,res2)
        return "reqE"

try:
    match sys.argv[1]:
        case "module":
            time.sleep(3)
            print(getHour())
        case "click":
            content = ""
            with open(path + "/electricityBill.cache", "r", encoding="utf-8") as f:
                res = json.load(f)
                su = sum(x['duringUsed'] for x in res["data"])
                content = f"<span font_size=\"17pt\">\
电量：%.2f 度\n\
电费：%.2f 元\n\
剩余: %.2f 度</span>" % (su,su*0.8,res["quantity"])
                for r in res["data"]:
                    t = time.strptime(r['createTime'], "%Y-%m-%dT%H:%M:%S")
                    content += "<span font_size=\"16pt\">%s</span>---%.2f\n" %(time.strftime('%H:%M:%S', t),r['duringUsed'])
                
                n = f"dunstify -t 15000 -i none  \
        '\t今日电量' '{content}'"
                print(n)
                os.system(n)
except BaseException as e:
    print(e)
    print("Err")

