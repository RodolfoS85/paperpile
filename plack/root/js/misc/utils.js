/* Copyright 2009-2011 Paperpile

   This file is part of Paperpile

   Paperpile is free software: you can redistribute it and/or modify it
   under the terms of the GNU Affero General Public License as
   published by the Free Software Foundation, either version 3 of the
   License, or (at your option) any later version.

   Paperpile is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Affero General Public License for more details.  You should have
   received a copy of the GNU Affero General Public License along with
   Paperpile.  If not, see http://www.gnu.org/licenses. */

Paperpile.utils = {

  // implementation from http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
  generateUUID: function() {
    // http://www.ietf.org/rfc/rfc4122.txt
    var s = [];
    var hexDigits = "0123456789ABCDEF";
    for (var i = 0; i < 32; i++) {
      s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1);
    }
    s[12] = "4"; // bits 12-15 of the time_hi_and_version field to 0010
    s[16] = hexDigits.substr((s[16] & 0x3) | 0x8, 1); // bits 6-7 of the clock_seq_hi_and_reserved to 01
    var uuid = s.join("");
    return uuid;
  },

  areHashesEqual: function(a, b) {
    // Quick shortcut: compare JSON strings.
    return (Ext.encode(a) == Ext.encode(b));
  },

  isBibtexMode: function() {
    return (Paperpile.main.getSetting('bibtex').bibtex_mode == 1);
  },

  midEllipse: function(string, length) {
    if (string.length > length) {
      return string.substring(0, length / 2) + ' ... ' + string.substring(length - length / 2, length);
    } else {
      return string;
    }
  },

  splitPath: function(path) {
    var parts = path.split('/');
    var file = parts[parts.length - 1];
    var newParts = parts.slice(0, parts.length - 1);
    var dir = newParts.join('/');

    var fileParts = file.split('.');
    var extension = fileParts[fileParts.length - 1];
    var newFileParts = fileParts.slice(0, fileParts.length - 1);
    var fileBase = newFileParts.join('.');

    return {
      dir: dir,
      file: file,
      extension: extension,
      base: fileBase
    };
  },

  // Returns true if path is absolute. Gets more interesting under Windows...
  isAbsolute: function(path) {

    return (path.substring(0, 1) == '/');

  },

  openURL: function(url) {
    if (IS_QT) {
      QRuntime.openUrl(url);
    } else {
      window.open(url, '_blank');
    }
  },

  openFile: function(file) {
    if (IS_QT) {
      QRuntime.openFile(file);
    } else {
      window.open('/serve/' + file, '_blank');
    }
  },

  setClipboard: function(value, msg) {
    if (IS_QT) {
      QRuntime.setClipboard(value);
      Paperpile.status.updateMsg({
        msg: msg,
        duration: 1.5,
        fade: true
      });
    }
  },

  isMac: function() {
    return this.get_platform() == 'osx';
  },

  get_platform: function() {

    var platform = '';

    if (IS_QT) {
      return (QRuntime.getPlatform());
    }

    return (platform);
  },

  // Encode label using our special format to allow unique full text searches
  encodeLabel: function(label) {

    label = label.replace(/ /g, "99");

    return '88' + label + '88';

  },

  hashToString: function(hash, recursive) {
    var string = "{\n";
    for (var key in hash) {
      if (hash.hasOwnProperty(key)) {
        var value = hash[key];
        string += "  " + key + "  =>  " + value + "\n";
      }
    }
    string += "}\n";
    return string;
  },

  catPath: function() {

    var parts = [];

    // Note: we can't run join on the arguments array which is
    // technically no array object
    for (var i = 0; i < arguments.length; ++i) {
      parts.push(arguments[i]);
    }

    return parts.join('/');
  },

  // The intended purpose of this function is to convert the GMT
  // timestamp to local time; for now it justs chops of the time
  // from the date string
  localDate: function(date) {
    return date.replace(/\d+:\d+:\d+/g, "");
  },

  secondsAgo: function(date_str) {
    var time = ('' + date_str).replace(/-/g, "/").replace(/[TZ]/g, " ");
    var dt = new Date;
    var seconds = ((dt - new Date(time) + (dt.getTimezoneOffset() * 60000)) / 1000);
    return seconds;
  },

  /*
 * Javascript Humane Dates
 * Copyright (c) 2008 Dean Landolt (deanlandolt.com)
 * Re-write by Zach Leatherman (zachleat.com)
 * 
 * Adopted from the John Resig's pretty.js
 * at http://ejohn.org/blog/javascript-pretty-date
 * and henrah's proposed modification 
 * at http://ejohn.org/blog/javascript-pretty-date/#comment-297458
 * 
 * Licensed under the MIT license.
 */

  prettyDate: function(date_str) {

    var time_formats = [
      [60, 'Just now'],
      [90, '1 minute'], // 60*1.5
    [3600, 'minutes', 60], // 60*60, 60
    [5400, '1 hour'], // 60*60*1.5
    [86400, 'hours', 3600], // 60*60*24, 60*60
    [129600, '1 day'], // 60*60*24*1.5
    [604800, 'days', 86400], // 60*60*24*7, 60*60*24
    [907200, '1 week'], // 60*60*24*7*1.5
    [2628000, 'weeks', 604800], // 60*60*24*(365/12), 60*60*24*7
    [3942000, '1 month'], // 60*60*24*(365/12)*1.5
    [31536000, 'months', 2628000], // 60*60*24*365, 60*60*24*(365/12)
    [47304000, '1 year'], // 60*60*24*365*1.5
    [3153600000, 'years', 31536000], // 60*60*24*365*100, 60*60*24*365
    [4730400000, '1 century'], // 60*60*24*365*100*1.5
    ];

    var time = ('' + date_str).replace(/-/g, "/").replace(/[TZ]/g, " ");
    var dt = new Date;
    var seconds = ((dt - new Date(time) + (dt.getTimezoneOffset() * 60000)) / 1000);
    var token = ' ago';
    var i = 0;
    var format;

    if (seconds < 0) {
      seconds = Math.abs(seconds);
      token = '';
    }

    while (format = time_formats[i++]) {
      if (seconds < format[0]) {
        if (format.length == 2) {
          return format[1] + (i > 1 ? token : ''); // Conditional so we don't return Just Now Ago
        } else {
          return Math.round(seconds / format[2]) + ' ' + format[1] + (i > 1 ? token : '');
        }
      }
    }

    // overflow for centuries
    if (seconds > 4730400000) return Math.round(seconds / 4730400000) + ' Centuries' + token;

    return date_str;
  }
};