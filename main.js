let config = {
	base_url: 'https://thingproxy.freeboard.io/fetch/https://vorarlbergtestet.lwz-vorarlberg.at',
	locations_path: '/GesundheitRegister/Covid/GetCovidTestLocationMassTest?betriebe=0',
	dates_path: '/GesundheitRegister/Covid/GetCovidTestDatesMassTest'
};

let domLocations = document.getElementById('locations');
let domSelected = document.getElementById('selected');
let domDates = document.getElementById('dates');

let dateRegistry = {};

function destructDate(key, date) {
	let reg = /(\d\d)\.(\d\d)\.(\d\d\d\d) (\d\d):(\d\d) - (\d\d):(\d\d) [^:]*: (\d+)/gmi;
	let a = reg.exec(date);
	let obj = {
		key: key,
		day: a[1],
		month: a[2],
		year: a[3],
		startHour: a[4],
		startMinute: a[5],
		endHour: a[6],
		endMinute: a[7],
		slots: a[8],
		original: date
	};
	obj.startDate = new Date(obj.year, obj.month - 1, obj.day, obj.startHour, obj.startMinute);
	obj.endDate = new Date(obj.year, obj.month - 1, obj.day, obj.endHour, obj.endMinute);
	return obj;
}

function destructLocation(location) {
	let reg = /^([^\ ]*) ([^,]*)(, (.*))?/gmi;
	let a = reg.exec(location);
	if(a == null) { // testbus
		return {
			place: location,
			city: "?",
			street: "?"
		}
	}
	return {
		place: a[2],
		city: a[1],
		street: a[4] ? a[4] : "" // landestheater
	};
}

function fillLocations(locations) {
	for(var i = 0; i < locations.length; i++) {
		let node = document.createElement('li');

		let cb = document.createElement('input');
		cb.type = 'checkbox';
		cb.name = 'location_' + i;
		cb.value = locations[i].value;
		cb.id = cb.name + "_cb";
		cb.onchange = function(ev){
			swapState(node);
		}
		node.appendChild(cb);

		let lbl = document.createElement('label')
		lbl.htmlFor = cb.id;
		lbl.appendChild(document.createTextNode(destructLocation(locations[i].value).city));
		node.appendChild(lbl);

		node.id = cb.name;
		node.dataset.key = locations[i].key;
		node.dataset.value = locations[i].value;
		node.onclick = function() {
			loadDates(this.dataset.key);
		}
		domLocations.appendChild(node);
	}
}

function swapState(node) {
	if(node.parentElement == domSelected) {
		domLocations.appendChild(node); //todo insert in right position
		node.draggable = false;
		node.ondragstart = node.ondragover = node.ondrop = null;
		fillDates();
	}
	else {
		domSelected.appendChild(node);
		node.draggable = true;
		node.ondragstart = function(ev) {
			ev.dataTransfer.setData("id", ev.target.id);
		}
		node.ondragover = function(ev) { event.preventDefault(); }
		node.ondrop = function(ev) {
			ev.preventDefault();
			domSelected.insertBefore(
				document.getElementById(ev.dataTransfer.getData("id")),
				ev.target.parentElement
			);
			fillDates();
		}
	}
}

function loadLocations(locations) {
	fetch(config.base_url + config.locations_path).then(function(response) {
		return response.json();
	}).then(function(locations) {
		fillLocations(locations);
	});	
}

function registerDates(location, dates) {
	dateRegistry[location] = [];
	for(let i = 0; i < dates.length; i++)
		dateRegistry[location].push(destructDate(dates[i].key, dates[i].value));
}

function fillDates(w) {
	domDates.innerHTML = '';
	if(!domSelected.firstChild) return;
	let location = domSelected.firstChild;
	let locations = [];
	do {
		locations.push(location.dataset.key);
	} while(location = location.nextSibling);
	let date = getFirstDate(locations);
	let endDate = new Date(date.getTime() + 1000 * 60 * 60 * 24 * 3);
	endDate.setHours(24, 0, 0);

	let info;
	while((info = getNextDate(locations, date)) && date < endDate) {
		let node = document.createElement('li');
		node.appendChild(document.createTextNode(info.date.original));
		domDates.appendChild(node);
		date = info.date.endDate;
	}

}

function getNextDate(locations, earliest) {
	let date = null;
	for(var i = 0; i < locations.length; i++) {
		for(let j = 0; j < dateRegistry[locations[i]].length; j++) {
			let itm = dateRegistry[locations[i]][j];
			if(itm.startDate < earliest) continue;
			if(!date || date.date.startDate > itm.startDate)
				date = { date: itm, location: locations[i] };
		}
	}
	return date;
}

function getFirstDate(locations) {
	let d = null;
	for(var i = 0; i < locations.length; i++) {
		if(!dateRegistry[locations[i]] || !dateRegistry[locations[i]].length) continue;
		if(!d || d > dateRegistry[locations[i]][0].startDate)
			d = dateRegistry[locations[i]][0].startDate;
	}
	return d;
}

function loadDates(location) {
	fetch(config.base_url + config.dates_path, {
	    "headers": {
	        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
	    },
	    "body": "ort=" + encodeURI(location.replaceAll(" ", "+")),
	    "method": "POST",
	    "mode": "cors"
	}).then(function(response) {
		return response.json();
	}).then(function(dates) {
		registerDates(location, dates);
		fillDates();
	});
}

window.onload = function(){
	loadLocations();
}
