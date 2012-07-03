var page_inits = [];

function setCookie (cookieName, cookieValue, nDays) {
	var today = new Date;
	var expire = new Date;
	if (nDays) {
		expire.setTime(today.getTime() + 3600000 * 24 * nDays);
	}
	document.cookie = cookieName + '=' + escape(cookieValue) + 
	(nDays ? ('; expires=' + expire.toGMTString()) : '') + '; path=/; domain=ybmanhua.com';
}

function getCookie (name) {
	var nameEQ = name + '=';
	var ca = document.cookie.replace(/\s/g, '').split(';');
	for (var i = 0; i < ca.length; i++) {
		var c = ca[i];
		if (c.indexOf(nameEQ) == 0)
			return unescape(c.substring(nameEQ.length, c.length).replace(/\+/g, ' '));
	}
	return null;
}

page_inits['index'] = function(){
    var start_loading = 0, show_loading_time = 500, loading_hide_timer = null;
    function show_loading()
    {
        start_loading = + new Date;
        $('#shelf-loading').show();
        if (loading_hide_timer) {
            clearTimeout(loading_hide_timer);
            loading_hide_timer = null;
        }
    }
    function hide_loading()
    {
        var t = + new Date, d = t - start_loading;
        if (d < show_loading_time) {
            loading_hide_timer = setTimeout(function(){
                $('#shelf-loading').hide();
            }, show_loading_time - d);
        } else {
            $('#shelf-loading').hide();
        }
    }
    
    var is_loading = false;
    function load_shelf(url, direction)
    {
        if (is_loading) return;
        is_loading = true;
        show_loading();
        $('#shelfs .pages').hide();
        var shelf_height = $('#shelfs .shelf:first').prop('offsetHeight');
        url += (url.indexOf('?') > -1 ? '&' : '?')
             + 'r=' + Math.ceil((+ new Date) / 60000);
        $.get(url, function(html){
            var $shelfs = $('#shelfs').append(html).find('.shelf');
            if (direction == 0) {
                $shelfs.first().remove();
                is_loading = false;
                hide_loading();
                $(window).triggerHandler('shelf_load');
                return;
            }
            var is_next = direction > 0;
            $shelfs.first()
            .css({
                position: 'absolute',
                left: 0,
                top : 0,
                zIndex : is_next ? 1 : 2
            }).addClass('origin-shelf').end().last()
            .css({
                position: 'absolute',
                left: 0,
                top: is_next ? shelf_height : (-shelf_height),
                zIndex: is_next ? 2 : 1
            }).end();
            $shelfs.animate({
                top : (is_next ? '-=' : '+=') + shelf_height
            }, 1000, function(){
				if (! $(this).is('.origin-shelf')) {
					$('#shelfs .origin-shelf').remove();
					is_loading = false;
					$(window).triggerHandler('shelf_load');
				}
            });
            hide_loading();
        });    
    }
    
    window.remove_from_shelf = function(id, elem, event) {
        event = $.event.fix(event);
        event.preventDefault();
        $.get('/shelf/remove?id=' + id, function(ret) {
            if (ret && ret.code == 0) {
                popup_msg(ret.msg, 'succ');
                load_shelf(cur_url, 0);
            } else {
                if (ret) {
                    popup_msg(ret.msg, 'error');
                } else {
                    popup_msg('服务器返回错误', 'error');
                }
            }
        }, 'json');
    };
    
    var cur_url = location.href;
    $('#shelfs a.next_page:not(.no_next_page),#shelfs a.prev_page:not(.no_prev_page)')
    .live('click', function(event) {
        event.preventDefault();
        cur_url = this.href;
        load_shelf(this.href, $(this).is('.next_page') ? 1 : -1);
    });
    
    var get_page = function(url) {
        page = 1;
        if (/\/(\d+)\//.test(url)) {
            page = parseInt(RegExp.$1);
        } else if (/page=(\d+)/.test(url)) {
            page = parseInt(RegExp.$1);
        }
        return page;
    };
    $(window).bind('shelf_load', function(){
        $('#shelfs .pages a:not([href^=javascript])')
        .click(function(event){
            event.preventDefault();
            load_shelf(this.href, get_page(this.href) > get_page(cur_url) ? 1 : -1);
            cur_url = this.href;
        });
        $('#shelfs .pages').show('fast');
    }).triggerHandler('shelf_load');
    
    $('#search input').keydown(function(event){
        event.stopPropagation();
        if (event.which == 13) {
            //event.preventDefault();
        }
        if (event.which == 27) {
            this.blur();
        }
    });
    
    $('button.sid-btn').click(function(){
        if ($(this).is('.sid-btn-disable')) {
            return;
        }
        var $t = $(this), sid = $.trim($t.prev().val());
        if (sid == '') {
            alert('请填写书架号');
            return;
        }
        $t.removeClass('sid-btn').addClass('sid-btn-disable');
        $.get('/shelf/reloadShelf/' + sid + '?t=' + Math.random(), function (ret) {
            $t.removeClass('sid-btn-disable').addClass('sid-btn');
            if (ret.indexOf('ok') > -1) {
                load_shelf('/mine', 0);
                if ($t.parent().is('.shelf-reload-cnt')) {
                    $t.parent().slideUp();
                }
            } else {
                alert(ret);
            }
        });
    });
    
    $(window).suggest({
        $input : $('#search input'),
        $show : $('#suggest-cnt .suggest-items'),
        url : '/book/suggest?kw={0}&r=' +  Math.ceil(+ new Date / (1000 * 3600 * 24)),
        //useJson : true,
        hideDelay : 0.5,
        delay : 0.1,
        valueField : 'name',
        process: function (o) {
            return '<div class="suggest-item"><span>'
            + o.name + '</span>'
            + '<span class="alias">' + o.site_name + '</span>'
            + '</div>';
        }
    });

    var intro_show_delay = 1000, intro_show_timer = null;
    $('.book').live('mouseenter', function(){
        $(this).css('zIndex', '100');
        var $e = $(this).find('.intro');
        intro_show_timer = setTimeout(function(){$e.show()}, intro_show_delay);
    }).live('mouseleave', function(){
        if (intro_show_timer) {
            clearTimeout(intro_show_timer);
            intro_show_timer = null;
        }
        $(this).css('zIndex', '0');
        $(this).find('.intro').hide();
    });
};

page_inits.period = function(){
    var start_p = null, start_page_p = null, $w = $(window), scroll_timer = null;
    function scroll_page (event) {
        event.preventDefault();
        var p = [event.clientX, event.clientY],
        delta_x = p[0] - start_p[0], delta_y = p[1] - start_p[1];
        $w.scrollLeft(start_page_p[0] - delta_x);
        $w.scrollTop(start_page_p[1] - delta_y);
    }
    $('#book-imgs').mousedown(function(event){
        if (event.target.tagName != 'A') {
            event.preventDefault();
            start_p = [event.clientX, event.clientY];
            start_page_p = [$w.scrollLeft(), $w.scrollTop()];
            $(document).mousemove(scroll_page);
        }
    }).mouseup(function(event){
        if (start_p) {
            $(document).unbind('mousemove', scroll_page);
            start_p = null;
        }
    });
    var img_fix_mode = false, origin_fw = window.fw,
    fix_width = function (img) {
            var screen_width =  document.documentElement.clientWidth * 0.98;
            if (img.width > screen_width) {
                img.style.width = screen_width + 'px';
            }
            origin_fw(img);
    };
    window.accessHandlers.F = function () {
        var screen_width =  document.documentElement.clientWidth * 0.98;
        if (img_fix_mode) {
            img_fix_mode = false;
            window.fw = origin_fw;
            $('div.img img').each(function(){
                this.style.width = '';    
            });
        } else {
            img_fix_mode = true;
            window.fw = fix_width;
            $('div.img img').each(function(){
                if ($(this).width() > screen_width) {
                    this.style.width = screen_width + 'px';
                }
            })
        }
    };
        
    if (!window.img_config) return;

    var start = img_config.start * 1, total = img_config.total * 1,
        batch = img_config.batch * 1,
        base_url = img_config.base_url,
        queue = [], loaded = {}, 
        max_loading_count = 3,
        loading_status = [],
        loading_timeout = 30,
        img_load_timer,
        add_to_queue = function($img) {
            var real_src = $img.attr('_src');
            if ( !real_src || $img.attr('src') == $img.attr('_src')) {
                return;
            }
            if (loaded[real_src]) {
                $img.attr('src', real_src);
                return;
            }
            queue.push($img);
            start_img_load_timer();
        };
    
    function start_img_load_timer ()
    {
        if (img_load_timer) return;

        img_load_timer = setInterval(img_load_handler, 1000);
    }
    
    function stop_img_load_timer ()
    {
        if (img_load_timer) {
            clearInterval(img_load_timer);
            img_load_timer = null;
        }
    }

    function preload (src) 
    {
        $.get(src + '&preload=1', function(){
            var img = new Image;
            img.onload = function() {
                loaded[src] = 1;
            };
            img.src = src;
        });
    }

    function img_load_handler() 
    {
        var new_loading_status = [];
        for (var i = 0; i < loading_status.length; i++) {
            var istatus = loading_status[i], $img = istatus.img;
            if (new Date - istatus.start_time > loading_timeout * 1000) {
                $img.attr('src', $img.attr('_src'));
                window.console && console.log('loading timeout #' + $img.attr('id'));
                continue;
            }
            if (loaded[$img.attr('_src')]) {
                $img.attr('src', $img.attr('_src'));
                continue;
            }
            new_loading_status.push(istatus);
        }
        loading_status = new_loading_status;

        if (queue.length == 0 && loading_status.length == 0) {
            return stop_img_load_timer();
        }

        var add_count = max_loading_count - loading_status.length;
        for (i = 0; i < add_count; i++) {
            if (queue.length == 0) break;
            var $img = queue.shift();
            loading_status.push({
                img : $img,
                start_time : + new Date
            });
            preload($img.attr('_src'));
        }
    }

    $('#book-imgs img').each(function(){
        add_to_queue($(this));
    });

    function show_nexts() {
        if (start > total) {
            return;
        }
        var i = start, end = Math.min(i + batch - 1, total), padstr = '00';
        for (; i <= end; i++) {
            var src = base_url + '&i=' + i;
            $('#nexts').before('<div class="img" id="i-' + i + '"><i>' + i + '</i><img id="img-' + i + '" src="/img/default.jpg" _src="' + src + '" onload="fw(this)" onerror="er(this)" onabort="er(this)"/></div>');    
            add_to_queue($('#img-' + i)); 
        }
        start = end + 1;
        if (end == total) {
            $('#nexts').hide();
            $('#period-guide').show();
        } else {
            $('.range').html(start + '-' + (start + Math.min(batch, total - end) - 1));
            $('#new-page-link').attr('href', $('#new-page-link').attr('href').replace(/start=\d+/, 'start=' + start));
        }
    }
    
    $('#nexts a:eq(0)').click(function(event){
        event.preventDefault();
        show_nexts();
    });

    for (var i = start; i < total; i++) {
        var $img = $('<img/>');
        $img.attr('_src', base_url + '&i=' + i); 
        add_to_queue($img);
    }
};

var accessHandlers = {
    B : function () { $(window).scrollTop($(document).height()) },
    T : function () { $(window).scrollTop(0) },
    S : function (event) { event.preventDefault(); var input = $('#search input')[0]; if (input) { input.select(); input.focus();}}
};
$(function(){
    $(document).keydown(function(event){
        if ($.inArray(event.target.tagName, ['INPUT', 'TEXTAREA', 'SELECT']) >= 0) {
            return;
        }
        
        if (event.ctrlKey || event.shiftKey || event.altKey || event.metaKey) {
            return;
        }

        var code = event.which;
        if (code >= 97 && code <= 122) {
            code -= 32;
        }
        if ((code >= 65 && code <= 90) || (code >= 48 && code <= 57) ) {
            var c = String.fromCharCode(code);
            var $elem = $('[accessKey=' + c + ']');
            if ($elem.length) {
                if ($elem.attr('accessEvent')) {
                    var evt = new $.Event($elem.attr('accessEvent'));
                    evt.preventDefault();
                    setTimeout(function(){$elem.trigger(evt);}, 0);
                } else if ($elem.attr('href')) {
                    if ($elem.attr('target') == '_blank') {
                        window.open($elem.attr('href'));
                    } else {
                        window.location = $elem.attr('href');    
                    }
                }
            } else {
                if (accessHandlers[c]) {
                    accessHandlers[c](event);
                }
            }
        }
    });
    
    if ($('ul#hots').length) {
        var $lis = $('ul#hots li'), index = 0, count = $lis.length, timer = null, interval = 5;
        $('ul#hots').append($lis.eq(0).clone());
        function next() {
            $lis.eq(index).hide('slow', function(){
                if (index == count) {
                    index = 0;
                    $lis.each(function(){$(this).show()});
                }
            });
             
            index++;    
        }
        timer = setInterval(next, interval * 1000);
        $lis.mouseenter(function(){
            if (timer) {
                clearInterval(timer);
                timer = null;
            }
        }).mouseleave(function(){
            if (timer == null) {
                timer = setInterval(next, interval * 1000);
            }
        });
        
    }
});

function add_to_shelf(id, elem, event, cb)
{
    event = $.event.fix(event);
    event.preventDefault();
    var $elem = $(elem);
    
    if ($elem.is('.add-done')) {
        return;
    }
    
    $elem.removeClass('add').addClass('add-done');
    $.get('/shelf/add?id=' + id + '&r=' + Math.random(), function(ret){
        if (! ret || ret.code != 0) {
            popup_msg(ret ? ret.msg : '服务器错误');
        } else {
            cb && cb(elem);
        }
    });
}


if (document.body && document.body.id && page_inits[document.body.id]) {
    $(page_inits[document.body.id]);
}

if (top != window) {
    //top.location = location.href;
}

//顶部弹出消息
$(function(){
    var $popup_msg = $('#popup-msg'), hideTimer = null, hideInterval = 10000,
    minShowTime = 500, startTime = 0;
    function popup_msg(msg, type)
    {
        type = type || 'error';
        $popup_msg.html(msg).show();
        $popup_msg.attr('class', type);
        var left = ($(window).width() - ($popup_msg.attr('offsetWidth') || $popup_msg.prop('offsetWidth'))) / 2;
        $popup_msg.css('left', left);//.hide().slideDown();
        startTime = + new Date;
        hideTimer = setTimeout(function(){ hide_msg() }, hideInterval);
    }
    
    function hide_msg()
    {
        if (hideTimer) {
            window.clearTimeout(hideTimer);
            hideTimer = null;
        }
        var showTime = + new Date - startTime;
        if (showTime < minShowTime) {
            hideTimer = setTimeout(function() { hide_msg() }, minShowTime - showTime);
            return;
        }
        $popup_msg.hide();
    }
    window.popup_msg = popup_msg;
    window.hide_popup_msg = hide_msg;
}); 

//添加漫画弹出
$(function(){
    $('#dialog-add-comic').dialog({
        autoOpen : false,
        width : 500,
        height : 200,
        modal : true,
        title : '快速添加漫画',
        buttons : {
            "添加漫画" : function() {
                var $f = $('#add-book-form'), $url = $f.find('input[name=url]');
                
                if ($.trim($url.val()) == '') {
                    $f.find('.err-msg').html('请填写地址。');
                    return;
                }

                if (! /^http/i.test($url.val())) {
                    $f.find('.err-msg').html('地址必须是以http开头的合法链接。'); 
                    return;
                }

                $f[0].submit();
            },
            "取消" : function() {
                $(this).dialog('close');
            }
        }
    });
    $('#add_comic_link').click(function(event){
        event.preventDefault();
    
        $('#dialog-add-comic').dialog('open');      
    });
});
