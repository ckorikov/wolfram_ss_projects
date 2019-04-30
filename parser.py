#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re

import requests
from bs4 import BeautifulSoup

welcome_msg = """
# Wolfram Summer School Projects

This page contains the list of projects of
the [Wolfram Summer School](https://education.wolfram.com/summer/school/).

"""


def get_data(get_link):
    req = requests.get(get_link)
    if req.status_code == 200:
        soup = BeautifulSoup(req.content, "html.parser")
        return soup
    return None


def process_project(report, link_to_project):
    project_data = get_data(link_to_project)
    if project_data:
        name_block = project_data.find("h1", class_="name")
        title_block = project_data.find("h2", string=re.compile("Project:"))
        name = name_block.text.encode('utf-8') if name_block else "Unknokwn"
        title = title_block.text.encode('utf-8') if title_block else "Unknokwn"
        report.write("* [**{}** {}]({})\n".format(title, name, link_to_project))


def process_list(report, link_to_list):
    list_data = get_data(link_to_list)
    if list_data:
        for lst in list_data.find("div", class_="alumni-list").find_all("li"):
            link_to_project = link_to_list + lst.find("a")["href"]
            print(link_to_project)
            process_project(report, link_to_project)


def main():
    with open("README.MD", "w") as report:
        report.write(welcome_msg)
        for year in reversed(range(2003, 2019)):
            link_to_list = "https://education.wolfram.com/summer/school/alumni/{}/".format(year)
            report.write("## [{}]({})\n\n".format(year, link_to_list))
            process_list(report, link_to_list)


if __name__ == '__main__':
    main()
