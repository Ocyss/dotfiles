#!/bin/env python3
# coding:utf-8
"""
Author: Ocyss qiudie@88.com
Date: 2023-07-12 10:50:24
Import: https://gitee.com/thecasttim/lrc-parser
"""
from mpd import MPDClient
import time
import os
import codecs
import re
from enum import Enum
import signal
import sys
import mutagen


MusicPath = "/home/ocyss/Music/"


# 正则表达式
# 标签匹配模式
TAG_PATTERN = r"\[.*?\]"
# 时间戳标签匹配模式
# (hh:)mm:ss(.xxx)
# hh:mm:ss(.xxx)时, hh可为任意整数, mm和ss在0~59之间, xxx在0~999之间或省略;
# mm:ss(.xxx)时, mm可为任意整数, ss在0~59之间, xxx在0~999之间或省略;
# TIME_PATTERN = r"^(\d+:){0,1}([0-5][0-9]:){0,1}([0-5][0-9])(\.[\d]{1,3}){0,1}$"
# 命名分组
TIME_PATTERN = r"^(?P<p1>\d+:){0,1}(?P<p2>[0-5][0-9]:){0,1}(?P<p3>[0-5][0-9])(?P<p4>\.[\d]{1,3}){0,1}$"
# 捕获分组
ENHANCE_TIME_PATTERN_C = (
    r"\<(\d+\:){0,1}([0-5][0-9]\:){0,1}([0-5][0-9])(\.[\d]{1,3}){0,1}\>"
)
# 非捕获分组
ENHANCE_TIME_PATTERN_N = (
    r"\<(?:\d+\:){0,1}(?:[0-5][0-9]\:){0,1}(?:[0-5][0-9])(?:\.[\d]{1,3}){0,1}\>"
)

# 标签类型


class TagType(Enum):
    ID = 0  # ID标签
    TIME = 1  # 时间戳标签
    UNKNOWN = 2  # 未知标签


class LrcParser:

    """解析Lrc歌词文件"""

    def __init__(self, music_file):
        text = ""
        lrcpath = MusicPath + os.path.splitext(music_file)[0] + ".lrc"
        if os.path.isfile(lrcpath):
            with codecs.open(lrcpath, "r", encoding="utf-8") as f:
                text = f.read()
        else:
            tags = mutagen.File(MusicPath + music_file)
            for v in tags.keys():
                if v.startswith("USLT"):
                    text = str(tags.get(v))
                    break
                elif v == "lyrics":
                    text = tags.get(v)[0]
                    break

        # 整个歌词文件的内容
        # 检查[]<>等标签括号是否匹配
        if not self.is_tags_valid(text):
            raise SyntaxError("lrc文件标签[]或<>不匹配")

        # 歌词列表
        #   每个元素为字典{
        #                'time': ...,
        #                'lyric': ...,
        #                'extends': {'timestamps': [...], 'parts': [...]}
        #               }
        #   -- time: 每段歌词前时间标签所标注的时间
        #   -- lyric：本time到下一个time标注之间的这段歌词(如:"[time1]lyric/n[time2]")
        #   -- parts：对于含有<mm:ss.xx>的增强格式的内容切分后的列表
        self.lyrics = []

        # 提取所有标签
        tags = [tag[1:-1] for tag in re.findall(TAG_PATTERN, text)]

        # 提取所有标签标注的内容
        segments = [segment.strip() for segment in re.split(TAG_PATTERN, text)]
        segments = segments[1:]  # split结果包含第一个标签前的字符(包括空字符), 将其丢弃

        tags_num = len(tags)
        if tags_num != len(segments):
            raise ValueError("标签数与标注内容个数不匹配, 请检查lrc文件")

        # 逐段解析标签及其内容
        for i in range(0, tags_num):
            tag_type = self.get_tag_type(tags[i])
            # 判断标签是时间标签还是ID标签, 分别处理
            if tag_type == TagType.TIME:
                res = {"time": self.parse_time_tag(tags[i])}
                # 普通格式
                res["lyric"] = segments[i]
                self.lyrics.append(res)

    @staticmethod
    def is_tags_valid(text):
        """
        检查标签括号是否匹配
        :param text: lrc歌词文件完整内容
        :return: 如果[]与<>匹配则返回True，否则返回False
        """
        if text is None:
            return True

        res = list()
        pair = {"]": "[", ">": "<"}
        for c in text:
            if c == "]" or c == ">":
                if not res or res[-1] != pair[c]:
                    return False
                res.pop()
            elif c == "[" or c == "<":
                res.append(c)

        return len(res) == 0

    @staticmethod
    def get_tag_type(tag):
        """
        获取标签类型
        :param tag: 标签
        :return: tag_type: 标签类型
        """
        # 时间戳标签匹配模式
        time_tag_pattern = TIME_PATTERN
        # ID标签匹配模式
        id_tag_pattern = r"[a-zA-Z]*:.*"

        if re.match(time_tag_pattern, tag):
            return TagType.TIME
        elif re.match(id_tag_pattern, tag):
            return TagType.ID
        else:
            return TagType.UNKNOWN

    @staticmethod
    def parse_time_tag(tag):
        """
        将时间戳解析为 时、分、秒、毫秒
        :param tag: 时间戳字符串
        :return: 时、分、秒、毫秒(整数)
        """
        time_pattern = TIME_PATTERN

        m = re.match(time_pattern, tag)
        time_parts = m.groupdict()

        # 毫秒
        ms = 0
        if time_parts["p4"] is not None:
            # ".xxx秒" ---> 毫秒
            ms = float(time_parts["p4"])

        # 秒
        s = 0
        if time_parts["p3"] is not None:
            s = int(time_parts["p3"])

        # 小时与分钟
        if time_parts["p2"] is None:
            h = 0
            if time_parts["p1"] is not None:
                # <p1>xx:<p3>xx(<p4>.xx)形式( xx:xx(.xx) )
                minute = int(time_parts["p1"][:-1])
                if minute >= 60:
                    h = minute // 60
                    minute = minute % 60
            else:
                # <p3>xx(<p4>.xx)形式( xx(.xx) )
                minute = 0
        else:
            h = int(time_parts["p1"][:-1])
            minute = int(time_parts["p2"][:-1])

        return h * 60 * 60 + minute * 60 + s + ms

    def get_lyrics(self):
        # 获取歌词列表
        return self.lyrics


# def len_format(string,width=23,fill= ' ',ed = ''):#格式输出函数,默认格式填充用单空格,不换行。
#     count = wcwidth.wcswidth(string)-len(string) #宽字符数量
#     width = width - count if width >= count else 0
#     return '{0:{1}^{2}}'.format(string,fill,width)

client = MPDClient()


def getLyrics():
    client.connect("localhost", 6600)
    cur = None
    lrc = None
    l = None
    while True:
        try:
            if cur is None or cur["file"] != client.currentsong()["file"]:
                cur = client.currentsong()
                lrc = LrcParser(cur["file"]).get_lyrics()
                l = 0
            status = client.status()
            t = float(status["elapsed"])
            while l < len(lrc) and lrc[l]["time"] < t:
                l += 1
            print("[{0}]".format(lrc[l - 1]["lyric"]))
            sys.stdout.flush()
            time.sleep(0.4)
        except BaseException:
            break
    getLyrics()


def quit(args, a):
    client.remove_command()
    exit(0)


if __name__ == "__main__":
    signal.signal(signal.SIGINT, quit)
    signal.signal(signal.SIGTERM, quit)
    getLyrics()
