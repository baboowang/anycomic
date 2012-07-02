#!/usr/bin/perl

# 监听地址
$listen = "http://*:3000";

system("morbo script/anycomic -l $listen");
