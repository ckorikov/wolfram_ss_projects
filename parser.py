#!/usr/bin/env python
# -*- coding: utf-8 -*-

import datetime
import re
import sys
from multiprocessing import Pool

import requests
from bs4 import BeautifulSoup

welcome_msg = """
# Wolfram Summer School Projects

This page contains the list of projects of
the [Wolfram Summer School](https://education.wolfram.com/summer/school/).

"""


def get_data(get_link: str):
    req = requests.get(get_link)
    if req.status_code == 200:
        soup = BeautifulSoup(req.content, "html.parser")
        return soup
    return None


def process_project(link_to_project: str):
    project_data = get_data(link_to_project)
    if project_data:
        name_block = project_data.find("h1", class_="name")
        title_block = project_data.find("h2", string=re.compile("Project:"))
        name = name_block.text if name_block else "Unknown"
        title = title_block.text if title_block else "Unknown"
        return f"* [**{title}** {name}]({link_to_project})\n"


def process_list(link_to_list: str):
    list_data = get_data(link_to_list)
    list_with_results = []
    if list_data:
        for lst in list_data.find("div", class_="alumni-list").find_all("li"):
            link_to_project = link_to_list + lst.find("a")["href"]
            print(link_to_project)
            data = process_project(link_to_project)
            if data:
                list_with_results.append(data)
    return list_with_results


def process_years(year: int):
    result = []
    link_to_list = f"https://education.wolfram.com/summer/school/alumni/{year}/"
    result.append(f"## [{year}]({link_to_list})\n\n")
    result += process_list(link_to_list)
    return result


def main():
    pool = Pool(4)
    from_year = 2003
    to_year = (len(sys.argv) > 1 and int(sys.argv[1])) or datetime.datetime.now().year
    data_list = pool.map(process_years, reversed(range(from_year, to_year)))

    with open("README.MD", "w") as report:
        report.write(welcome_msg)
        for data_list in data_list:
            for line in data_list:
                report.write(line)


if __name__ == "__main__":
    main()
