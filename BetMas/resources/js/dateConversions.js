/*!
 * Functions to Convert Between Ethiopic dates, Western (Julian/Gregorian) dates, and Islamic dates
 * By Augustine Dickinson
 * 
 * Modified from https://github.com/ethiopicist/Calendar/blob/master/scripts/src/conversion.js
 *
 * Copyright (c) 2020 Ethiopicist.com and its contributors.
 *
 * @licence MIT License
 */

/**
 * Converts a date and returns the converted date as a readable string.
 * @param {('ethiopic'|'western'|'gregorian'|'julian')} calendar
 * @param {number} year Must be greater than 0
 * @param {number|string} month Must be from 1 to 13
 * @param {number} [date] Optional
 * @param {('amata-seggawe'|'amata-alam','anno-domini')} [era] Optional; default is 'amata-seggawe' for 'ethiopic' and 'anno-domini' for 'western'
 */
function convertDate(calendar, year, month, date, era) {

  if(typeof year !== "number") year = parseInt(year);
  if(typeof month !== "number" && !isNaN(parseInt(month))) month = parseInt(month);
  if(typeof date !== "number" && !isNaN(parseInt(date))) date = parseInt(date);

  // ethiopic to western
  if(calendar == 'ethiopic') {

    // if month is string (like maskaram) then change to number
    if(typeof month !== "number") month = ethiopianMonthsAscii[month];

    // check if year needs to be converted based on era
    if(era !== undefined) {
      if(era == 'amata-alam') year -= 5500;
      else if(era == 'anno-domini') {
        if(month < 5) year -= 7;
        else year -= 8;
      }
    }

    const origDate = {
      year: year,
      month: month
    }
    if(typeof date == "number") origDate.date = date;
    else origDate.date = 15;

    const convDate = toWestern(origDate);

    return (typeof date == "number" ? convDate.date+' ' : '') + westernMonths[convDate.month] + ' ' + convDate.year;

  }

  // western to ethiopic
  else if(
    calendar == 'western' ||
    calendar == 'gregorian' ||
    calendar == 'julian'
  ) {

    const origDate = {
      year: year,
      month: month
    }
    if(typeof date == "number") origDate.date = date;

    const convDate = toEthiopic(origDate);

    return (typeof date == "number" ? convDate.date+' ' : '') + ethiopianMonths[convDate.month] + ' ' + convDate.year + ' (' + (convDate.year+5500) + ')';

  }

}

/**
 * To convert an Ethiopic date to a JDN.
 * @param {{year: number, month: number, date: number}} date 
 */
function ethiopicToJdn(date){

  // Verify that the argument for date is a valid type

  if(typeof date !== 'object'){
      console.log('Parameter date expects an object.');
      return false;
  }
  else if(!('year' in date) || !('month' in date)){
      console.log('Parameter date must contain a year and a month.');
      return false;
  }
  else if(!('date' in date)) date.date = 1;

  if(
      (typeof date.year !== 'number' && typeof date.year !== 'string') ||
      (typeof date.month !== 'number' && typeof date.month !== 'string') ||
      (typeof date.date !== 'number' && typeof date.date !== 'string')
  ){
      console.log('Values for date must be numbers or strings.');
      return false;
  }
  else{
      date.year = parseInt(date.year);
      date.month = parseInt(date.month);
      date.date = parseInt(date.date);
  }

  // Verify that the argument for date is a valid date

  if(date.month < 1 || date.month > 13){
      console.log('date.month must be an integer from 1 (Mas) to 13 (Pag).');
      return false;
  }
  else if(date.date < 1 || date.date > 30){
      console.log('date.date must be an integer from 1 to 30.');
      return false;
  }
  else if(date.month == 13){
      if(
          date.year % 4 == 3 &&
          date.date > 6
      ){
          console.log('In leap years, if date.month == 13 then date.date must be <=6.');
          return false;
      }
      else if(
      date.year % 4 != 3 &&
      date.date > 5
      ){
          console.log('In non-leap years, if date.month == 13 then date.date must be <=5.');
          return false;
      }
  }

  // If date < 1/1/1 then error

  if(date.year < 1){
      console.log('Dates before 1/1/1 AM are invalid.');
      return false;
  }

/*
    This formula is based on the one describe by Daniel Yacob here:
    http://www.geez.org/Calendars/
*/

  const n = 30 * date.month + date.date - 31;
  const jdn = (1723856 + 365) + 365 * (date.year - 1) + Math.floor(date.year / 4) + n - 0.5;

  return jdn;

}

/**
 * To convert a Western date to a JDN,
 * where "Western" is defined as:
 * Gregorian for dates on or after October 15, 1582 or
 * Julian for dates on or before October 4, 1582.
 * @param {{year: number, month: number, date: number}} date 
 */
function westernToJdn(date){
  // Verify that the argument for date is a valid type
  
  if(typeof date !== 'object'){
      console.log('Parameter date expects an object.');
      return false;
  }
  else if(!('year' in date) || !('month' in date)){
      console.log('Parameter date must contain a year and a month.');
      return false;
  }
  else if(!('date' in date)) date.date = 1;
  
  if(
      (typeof date.year !== 'number' && typeof date.year !== 'string') ||
      (typeof date.month !== 'number' && typeof date.month !== 'string') ||
      (typeof date.date !== 'number' && typeof date.date !== 'string')
  ){
      console.log('Values for date must be numbers or strings.');
      return false;
  }
  else{
      date.year = parseInt(date.year);
      date.month = parseInt(date.month);
      date.date = parseInt(date.date);
  }
  
  // Verify that the argument for date is a valid date
  
  if(date.month < 1 || date.month > 12){
      console.log('date.month must be an integer from 1 (Jan) to 12 (Dec).');
      return false;
  }
  else if(date.date < 1 || date.date > 31){
      console.log('date.date must be an integer from 1 to 31.');
      return false;
  }
  else if(
      (date.month == 4 || date.month == 6 || date.month == 9 || date.month == 11) && date.date > 30
  ){
      console.log('For date.month in [4,6,9,11] date.date must be <= 30.');
      return false;
  }
  else if(date.month == 2){
      if(
          date.year % 4 == 0 &&
          (date.year <= 1582 ||
          date.year % 100 != 0 ||
          date.year % 400 == 0) &&
          date.date > 29
      ){
          console.log('In leap years, if date.month == 2 then date.date must be <=29.');
          return false;
      }
      else if(date.date > 28){
          console.log('In non-leap years, if date.month == 2 then date.date must be <=28.');
          return false;
      }
  }

/*
    These formulas are based on the ones described by Bill Jeffreys here:
    https://quasar.as.utexas.edu/BillInfo/JulianDatesG.html
*/

  // First convert to JDN
  // This formula can be adjusted for both
  // Julian and Gregorian
  
  if(date.month < 3){
      date.year--;
      date.month += 12;
  }
  
  const a = Math.floor(date.year / 100);
  const b = Math.floor(a / 4);
  const c = 2 - a + b;
  const e = Math.floor(365.25 * (date.year + 4716));
  const f = Math.floor(30.6001 * (date.month + 1));
  
  // Use Gregorian conversion for dates >= 1582/10/15
  // Use Julian conversion for dates <= 1582/10/4
  // If 1582/10/4 < date > 1582/10/15 then error
  // Or if date < 8/8/29
  
  if(
      date.year < 8 ||
      (date.year == 8 && date.month < 8) ||
      (date.year == 8 && date.month == 8 && date.date < 29)
  ){
      console.log('Dates before 8/8/29 are invalid.');
      return false;
  }
  else if(
      date.year < 1582 ||
      (date.year == 1582 && date.month < 10) ||
      (date.year == 1582 && date.month == 10 && date.date <= 4)
  ){
      var jdn = date.date + e + f - 1524.5;
  }
  else if(
      date.year > 1582 ||
      (date.year == 1582 && date.month > 10) ||
      (date.year == 1582 && date.month == 10 && date.date >= 15)
  ){
      var jdn = c + date.date + e + f - 1524.5;
  }
  else{
      console.log('Dates from 1582/10/5 to 1582/10/14 are invalid.');
      return false;
  }

  return jdn;
  
}

/**
 * To convert a JDN date to an Ethiopic date,
 * @param {number} jdn A Julian Day Number 
 */
function jdnToEthiopic(jdn){

/*
    This formula is based on the one describe by Daniel Yacob here:
    http://www.geez.org/Calendars/
*/

  const r = (jdn - 1723855.5) % 1461;
  const n = (r % 365) + 365 * Math.floor(r / 1460);

  date = {};    
  date.year = 4 * Math.floor((jdn - 1723856) / 1461) + Math.floor(r / 365) - Math.floor(r / 1460);
  date.month = Math.floor(n / 30) + 1;
  date.date = (n % 30) + 1;

  return date;
}

/**
 * To convert a JDN to a Western date,
 * where "Western" is defined as:
 * Gregorian for dates on or after October 15, 1582 or
 * Julian for dates on or before October 4, 1582.
 * @param {number} jdn A Julian Day Number
 */
function jdnToWestern(jdn){
  
  // Use Gregorian conversion for dates >= 1575/2/8 (JDN 2299160.5)
  // Use Julian conversion for dates <= 1575/2/7 (JDN 2299159.5)

/*
    These formulas are based on the ones described by Bill Jeffreys here:
    https://quasar.as.utexas.edu/BillInfo/JulianDatesG.html
*/
  
  const q = jdn + 0.5;
  const z = Math.floor(q);
  
  if(jdn < 2299160.5){
      var a = z;
  }
  else{
      const w = Math.floor((z - 1867216.25) / 36524.25);
      const x = Math.floor(w / 4);
      var a = z + 1 + w - x;
  }
  
  const b = a + 1524;
  const c = Math.floor((b - 122.1) / 365.25);
  const d = Math.floor(365.25 * c);
  const e = Math.floor((b - d) / 30.6001);
  const f = Math.floor(30.6001 * e);
  
  date = {};
  date.date = b - d - f + (q - z);
  date.month = (e - 1 <= 12 ? e - 1: e - 13);  
  date.year = (date.month <= 2 ? c - 4715 : c - 4716);
  
  return date;

}

/**
 * To convert an Ethiopic date to a Western date,
 * where "Western" is defined as:
 * Gregorian for dates on or after October 15, 1582 or
 * Julian for dates on or before October 4, 1582.
 * @param {{year: number, month: number, date: number}} date An Ethiopic date
 */
function toWestern(date){

  return jdnToWestern(ethiopicToJdn(date));

}

/**
 * To convert an Ethiopic date to a Western date,
 * where "Western" is defined as:
 * Gregorian for dates on or after October 15, 1582 or
 * Julian for dates on or before October 4, 1582.
 * @param {{year: number, month: number, date: number}} date An Ethiopic date
 */
function toEthiopic(date){

  return jdnToEthiopic(westernToJdn(date));

}

const westernMonths = ['',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

const ethiopianMonths = ['',
  'Maskaram',
  'Ṭǝqǝmt',
  'Ḫǝdār',
  'Tāḫśāś',
  'Ṭǝrr',
  'Yakkātit',
  'Maggābit',
  'Miyāzyā',
  'Gǝnbot',
  'Sane',
  'Ḥamle',
  'Naḥase',
  'Ṗāgʷǝmen'
];

const ethiopianMonthsAscii = {
  maskaram: 1,
  teqemt: 2,
  hedar: 3,
  tahsas: 4,
  terr: 5,
  yakkatit: 6,
  maggabit: 7,
  miyazya: 8,
  genbot: 9,
  sane: 10,
  hamle: 11,
  nahase: 12,
  pagwemen: 13
};