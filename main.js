let config = {
	proxy_url: 'https://digitaleinitiativen.at/testen/proxy.php?csurl=',
	base_url: 'https://vorarlbergtestet.lwz-vorarlberg.at',
	locations_path: '/GesundheitRegister/Covid/GetCovidTestLocationMassTest&betriebe=0',
	dates_path: '/GesundheitRegister/Covid/GetCovidTestDatesMassTest'
};

let domLocations = document.getElementById('locations');
let domSelected = document.getElementById('selected');
let domDates = document.getElementById('dates');

let dateRegistry = {};

let colors = [
	"#eddcd2ff",
	"#fff1e6ff",
	"#fde2e4ff",
	"#fad2e1ff",
	"#c5deddff",
	"#dbe7e4ff",
	"#f0efebff",
	"#d6e2e9ff",
	"#bcd4e6ff",
	"#99c1deff"
];

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
	location = location.replaceAll("Düns Feuerwehrhaus", "Düns Feuerwehrhaus,")
	let reg = /^((St\. )?(Langen bei Bregenz)?(Anton im Montafon)?[^\, ]*) ?([^,]*), (.*)?/gmi;
	let a = reg.exec(location);
	if(a == null) { // testbus
		return {
			place: location,
			city: "?",
			street: "?"
		}
	}
	return {
		place: a[5],
		city: a[1] ? a[1] : "",		// sulzberg-thal
		street: a[6] ? a[6] : "" 	// landestheater
	};
}

function fillLocations(locations) {
	for(var i = 0; i < locations.length; i++) {
		let location = destructLocation(locations[i].value);

		let node = document.createElement('li');

		let cb = document.createElement('input');
		cb.type = 'checkbox';
		cb.name = 'location_' + i;
		cb.value = locations[i].value;
		cb.id = cb.name + "_cb";
		cb.onchange = function(ev){
			swapState(node);
			loadDates(this.parentNode.dataset.key);
		}
		node.appendChild(cb);

		let lbl = document.createElement('label')
		lbl.htmlFor = cb.id;
		lbl.appendChild(document.createTextNode(location.city));
		node.appendChild(lbl);

		let small = document.createElement('small');
		small.appendChild(document.createTextNode(location.place));
		node.appendChild(small);

		node.id = cb.name;
		node.dataset.key = locations[i].key;
		node.dataset.value = locations[i].value;
		domLocations.appendChild(node);
	}

	let prefill = getCookie('locations').split('|');
	for(let i = 0; i < domLocations.children.length; i++) {
		if(prefill.includes(domLocations.children.item(i).dataset.key)) {
			loadDates(domLocations.children.item(i).dataset.key);
			swapState(domLocations.children.item(i));
		}
	}

}

function swapState(node) {
	if(node.parentElement == domSelected) {
		domLocations.appendChild(node); //todo insert in right position
		node.style.backgroundColor = "";
		node.draggable = false;
		node.ondragstart = node.ondragover = node.ondrop = null;
	} else {
		domSelected.appendChild(node);
		node.style.backgroundColor = colors[
			Math.min(domSelected.children.length - 1, colors.length - 1)
		];
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
			for(let i = 0; i < domSelected.children.length; i++) {
				domSelected.children.item(i).style.backgroundColor = colors[
					Math.min(i, colors.length - 1)
				];
			}
			fillDates();
		}
	}
	fillDates();
}

function loadLocations(locations) {
	fetch(config.proxy_url + config.base_url + config.locations_path).then(function(response) {
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

function fillDates() {
	domDates.innerHTML = '';
	if(!domSelected.firstChild){
		setCookie('locations', "");
		return;
	}
	let location = domSelected.firstChild;
	let locations = [];
	do {
		locations.push(location.dataset.key);
	} while(location = location.nextSibling);

	setCookie('locations', locations.join("|"));

	let date = getFirstDate(locations);
	if(!date) return false;

	let endDate = new Date(date.getTime() + 1000 * 60 * 60 * 24 * 5);
	endDate.setHours(24, 0, 0);

	let info;
	while((info = getNextDate(locations, date)) && date < endDate) {
		if(!domDates.children.length || date.getDay() != info.date.endDate.getDay()) {
			let node = document.createElement('li');
			node.classList.add("date");
			node.appendChild(document.createTextNode(
				info.date.day + "." + info.date.month + "." + info.date.year
			));
			let small = document.createElement('small');
			small.appendChild(document.createTextNode(
				"........................"
			));
			node.appendChild(small);
			domDates.appendChild(node);			
		} else if(date < info.date.startDate) {
			let node = document.createElement('li');
			node.appendChild(document.createTextNode(
				(date.getHours() < 10 ? "0" : "") + date.getHours() + ":" +
				(date.getMinutes() < 10 ? "0" : "") + date.getMinutes() + "-" +
				(info.date.startDate.getHours() < 10 ? "0" : "") + info.date.startDate.getHours() + ":" + 
				(info.date.startDate.getMinutes() < 10 ? "0" : "") + info.date.startDate.getMinutes() +
				" (0)"
			));
			let small = document.createElement('small');
			small.appendChild(document.createTextNode(
				"sorry, we are out"
			));
			node.appendChild(small);
			domDates.appendChild(node);			
		}

		let node = document.createElement('li');
		node.appendChild(document.createTextNode(
			info.date.startHour + ":" + info.date.startMinute + "-" +
			info.date.endHour + ":" + info.date.endMinute +
			" (" + info.date.slots + ")"
		));
		let small = document.createElement('small');
		small.appendChild(document.createTextNode(
			destructLocation(info.location).city + " " + destructLocation(info.location).place
		));
		node.appendChild(small);
		domDates.appendChild(node);
		node.style.backgroundColor = colors[
			Math.min(info.index, colors.length - 1)
		];
		date = info.date.endDate;
	}

}

function getNextDate(locations, earliest) {
	let date = null;
	for(var i = 0; i < locations.length; i++) {
		if(!dateRegistry[locations[i]]) continue;
		for(let j = 0; j < dateRegistry[locations[i]].length; j++) {
			let itm = dateRegistry[locations[i]][j];
			if(itm.startDate < earliest) continue;
			if(!date || date.date.startDate > itm.startDate)
				date = { date: itm, location: locations[i], index: i };
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
	fetch(config.proxy_url + config.base_url + config.dates_path + "&ort=" + encodeURI(location.replaceAll(" ", "+"))).then(function(response) {
		return response.json();
	}).then(function(dates) {
		registerDates(location, dates);
		fillDates();
	});
}

function setCookie(cname, cvalue, exdays) {
  var d = new Date();
  d.setTime(d.getTime() + (exdays * 24 * 60 * 60 * 1000));
  var expires = "expires="+d.toUTCString();
  document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/; SameSite=Strict";
}

function getCookie(cname) {
  var name = cname + "=";
  var ca = document.cookie.split(';');
  for(var i = 0; i < ca.length; i++) {
    var c = ca[i];
    while (c.charAt(0) == ' ') {
      c = c.substring(1);
    }
    if (c.indexOf(name) == 0) {
      return c.substring(name.length, c.length);
    }
  }
  return "";
}

window.onload = function(){
	loadLocations();
}
