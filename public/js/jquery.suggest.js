/**
 * @file jQuery.suggest.js
 * @description
 * 	bind input element for text suggestion
 * $id:v1.0.0, 2009-07-10 10:50, baboo<istxwang@gmail.com>$
 */
(function ($) {

 $.fn.suggest = function (options) {
	options = $.extend({
		noResultText: 'No Result!',	
		hideWhenNoResult: true,
		$flashMaskLayer: false,
		className: 'suggest-item',
		classNameSelected: 'suggest-item-selected',
		delay: 1,
		hideDelay: 0.3,
		valueField: 0,
		useJson: false,
		noCache : false,
		getRetArr : function (j) { return j && j.result },
		getRetWord : function (j) { return j && j.word },
		getDataSource : false,
		strict: 1	//when strict == 1, before request send, the word will be checked if in no-result words prefix
	}, options);
	var 
		//the text input element to bind typing
		$input = options.$input, 
		//the suggest text container layer
		$show = options.$show, 
		//to fixed the problem that flash is alway up the show layer
		//the flashMaskLayer is a block element that contians a iframe element
		$flashMaskLayer = options.$flashMaskLayer,

		lastChoosed = null, 
		
		lastShowValue = null, 
        lastValue = null, 
        oriValue = null, 
        timer = null, 
        hideTimer = null, 
        is_blur = true,
        _t = this,
		//clear the suggest layer show timer
		clearTimer = function () {if (timer) clearTimeout(timer); timer = null},
		
		//set the suggest layer hide timer
		setHideTimer = function () {
			if ($show.css('display') == 'none') 
				return;
			clearHideTimer();
			hideTimer = setTimeout(hide, options.hideDelay * 1000);	
		},
		
		//clear the suggest layer hide timer
		clearHideTimer = function () {
			if (hideTimer != null) {
				clearTimeout(hideTimer);	
				hideTimer = null;
			}
		}

		//a function do nothing, used as default handle 
		nothing = function () {};

	if (!($input && $input.length && $show && $show.length))
		throw "$.suggest options required: $input and $show";
	
	var KEY_DOWN = 40, KEY_UP = 38, KEY_ESC = 27, KEY_ENTER = 13;

	var onkeydownorup = function (event) { 
		var code = event.which;
		
        is_blur = false;

		//for browsers that in keyup event can't capture 'down' key
		if (event.type == 'keydown' && code == KEY_DOWN)
			return chooseNext();
			
		switch(code) {
			case KEY_DOWN: 
				!$.browser.opera && chooseNext();
				return; 
			case KEY_UP: 
				chooseNext(true);
				return;
			case KEY_ENTER:
				hide();
				(options.onPressEnter || nothing)(event, this);
				return;
			 case KEY_ESC: 
				hide();
				return;
			 default: 
				checkValue();
		}	
	}; 
	
	//input blur event handler

	var onblur = function () { 
		hide(); 
		clearTimer(); 
        is_blur = true;
	};
	
	//tool function
	var v = function () { return $.trim($input.val()).toLowerCase() };  

	var checkValue = function () {
		var value = v();
		if (lastShowValue == value && $show.css('display') != 'none') return;
		lastValue = value;
		setHideTimer();
		if (lastValue == '' ||(options.strict == 1 && $.fn.suggest.NoResultPrefix.has(lastValue))) {
			clearHideTimer();
			hide();
			return; 
		}
		if (!options.delay) 
			return show(lastValue);
		clearTimer ();
		timer = setTimeout(function(){
            delayShow(lastValue);
        }, options.delay * 1000);	
	};
	
	var delayShow = function (w) { 
		if (w == v()) show(w);	
	}; 
	
	var show = function (w) {
		//clearHideTimer();
		//如果存在获取相关文本对象的接口函数，则通过该函数获取对象
		if (options.getDataSource) {
			return realShow(options.getDataSource(w));	
		}
		
		var url = options.url.replace(/\{0\}/, encodeURIComponent(w));
		if (options.noCache) url  += '&rand=' + Math.random();
		$.get(url, null, function (json) {
			realShow(json);
		}, options.useJson ? 'jsonp' : 'json');
	} ; 
	var realShow = function (o) {
		var w = options.getRetWord(o);
		var result = options.getRetArr(o);
		if (!w || w != v() || !result || is_blur) {
			return;
		}
		lastShowValue = w;
		lastChoosed = null;
		var sb = [];
		if (options.prefix) sb.push(options.prefix);
		if (result.length == 0) $.fn.suggest.NoResultPrefix.add(w);
		for (var i = 0; i < result.length; i ++) {
			sb.push(options.process(result[i], i));	
		}
		if (result.length == 0) {
			if (options.hideWhenNoResult) return;
			sb.push(options.noResultText);
		}
		clearHideTimer();
		if (options.suffix) sb.push(options.suffix);
		$show.html(sb.join(''));
		($show.find('> *.' + options.className) || []).each(
			function (i, e) { 
				e.title = result[i][options.valueField];
				e.onmouseover = function() {choose(e, true)};
				e.onmousedown = function (){check(e.title)};	
			}
		);
		$show.css('visibility', 'hidden').css('display', '');
		if ($flashMaskLayer) {
			$flashMaskLayer.css('height', $show[0].offsetHeight + 'px').show();
			var $iframe = $flashMaskLayer.find('iframe');
			if ($iframe) $iframe.css('height', $show[0].offsetHeight + 'px');
		}
		$show.css('visibility', 'visible');
	};
	var hide = function () {
		if ($show.css('display') == 'none') return;
		if ($flashMaskLayer) $flashMaskLayer.hide();
		$show.hide();
		options.onHide && options.onHide();
		lastChoosed = null;
	};
	/**
	  *  public function
	  */
	var activated = false;
	this.activate = function () {
		if (activated) return;
		if ($.isOpera) {
			$input.keydown(onkeydownorup);
		} 
		$input.keyup(onkeydownorup); 
		$input.blur(onblur);
		activated = true;
		return this;
	};
	
	this.disable = function () {
		if (!activated) return;
		if ($.isOpera) {
			$input.unbind('keydown', onkeydownorup);
		} 
		$input.unbind('keyup', onkeydownorup);
		$input.unbind('blur', onblur);
		clearTimer();
		activated = false;	
		return this;
	};	
	
	this.setUrlTpl = function (newUrl) {
		options.url = newUrl;
		lastShowValue=null;
		lastValue=null;
		if (options.strict == 1) $.fn.suggest.NoResultPrefix.length = 0;
		return this;
	};
	var check = function (w) {
		lastValue = w;
		$input.val(w);
		hide();	
		if (options.onCheck)  options.onCheck($input);
	};
	
	var unchoose = function (o) {
		$(o).removeClass(options.classNameSelected);
	}; 

	var choose = function (o, doNotChangeValue) {
		if (lastChoosed) unchoose(lastChoosed);
		if (o === null) {
			lastChoosed = null;
			return $input.val(oriValue || '');
		}
		$(o).addClass(options.classNameSelected);
		lastChoosed = o;
		if (!doNotChangeValue) {
			var w = o.title;
			lastValue = w.toLowerCase();
			$input.val(w);
		}
	};
	this.choose = choose;
	var chooseNext = function (up) { 
		if ($show.css('display') == 'none') return;
		var es = $show.find('.' + options.className);
		if (!es.length) return;
		if (lastChoosed == null) {
			oriValue = $input.val();
			if (up) return choose(es.filter(':last').get(0));
			return choose(es[0]);
		}
		
		var i;
		for (i = 0; i < es.length; i ++) {
			if (lastChoosed == es[i]) break;
		}
		if (up) {
			if (i == 0) return choose(null);	
			return choose(es[--i]);
		}
		if (i == es.length - 1) return choose(null);
		return choose(es[++i]);
	} ;
	this.__show = realShow;
	this.activate();
};
$.fn.suggest.NoResultPrefix = {
	list: [],
	add: function (w) { this.list.push(w) },
	has: function (w) {
		if(!w) return false;
		for (var i = 0; i < this.list.length; i ++) {
			if (w.indexOf(this.list[i]) == 0) return true;	
		}	
		return false;
	}
};

})(jQuery);
