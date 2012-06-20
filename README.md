# 实现原理：
AnyComic在本地搭建了一个实时的漫画采集站点，通过配置文件描述漫画站点的页面结构，识别各个漫画站的漫画链接，将漫画的元信息和图片保存在本地。

**默认支持的网站：**
* 笨蛋漫画 bengou.com
* 爱漫画 imanhua.com
* 有妖气 u17.com

# 安装：
1. 安装perl，版本5.12或以上。

    Window操作系统请下载 [ActivePerl](http://www.activestate.com/activeperl/downloads)

    Linux/Mac 等类Unix系统都自带Perl，请检查下版本号，版本过低请升级。

2. 下载 [AnyComic应用](https://github.com/baboowang/anycomic/zipball/master)

3. 进入应用目录，运行安装脚本setup.bat (非Window系统运行setup.sh)

4. 运行start.bat启动服务 (非Window系统运行start.sh)

# 使用方法：
服务启动成功，你会看到一行类似下面的输出信息：
Server available at http://127.0.0.1:3000

之后，你就可以用你最习惯的浏览器打开 http://127.0.0.1:3000 。
点击页面顶部的添加漫画或按快捷键A，会弹出一个输入框，输入漫画链接后，就可以将漫画加入书架了。

开始享受爽歪歪的漫画之旅吧。
