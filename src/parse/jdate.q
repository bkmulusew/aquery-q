/ jdate.q - check and re-print date and timestamp literals the way Java does.

/ Ported from aquery-master/src/main/scala/edu/nyu/aquery/parse/AqueryTokens.scala.
/ Scala hands the literal's text to Java's SimpleDateFormat, non-lenient,
/ with one of two patterns:
/     date:       MM/dd/yyyy               e.g. 01/02/2020
/     timestamp:  MM/dd/yyyy'D'HH:mm:ss    e.g. 01/02/2020D10:11:12
/ and prints the parsed value back with the same pattern. Java's rules:
/   - A number field skips spaces and tabs in front of it, then reads as
/     many digits as there are ("1" and "001" both fit "MM"). Java reads
/     numbers with DecimalFormat, which also takes an exponent: "1E3" is
/     1000, "2E-3" is 0.002 (so 0). The value is then cut to a Java int.
/   - Literal characters ("/", "D", ":") must match exactly.
/   - Only the START of the text has to fit; anything after is ignored.
/   - Non-lenient: month 1-12, a day that exists in that month, year 1 to
/     292278994, hour 0-23, minute and second 0-59. The calendar is Julian
/     before 15 Oct 1582 (02/29/1500 is valid; 5-14 Oct 1582 do not exist).
/   - Printing pads every field to 2 digits and the year to 4.
/ Not modelled: Java also rejects a time inside a daylight-saving gap of
/ the machine's time zone. No test input hits that.


/ A pattern is a list of steps: a symbol reads a number into that field,
/ a character is literal text that must come next.
.aqc.jdate.DATE:(`month;"/";`day;"/";`year);
.aqc.jdate.TIMESTAMP:(`month;"/";`day;"/";`year;"D";`hour;":";`minute;":";`second);


/ ---------------------------------------------------------------------------
/ Reading numbers
/ ---------------------------------------------------------------------------

/ skipDigits[txt; i]
/   Index of the first character at or after i that is not a digit.
/     skipDigits["12ab"; 0]   is 2
.aqc.jdate.skipDigits:{[txt;i]
  while[(i < count txt) and txt[i] in .Q.n; i+:1];   / .Q.n is "0123456789"
  i};

/ javaInt[number]
/   Java's intValue(): keep the low 32 bits of a long as a signed int.
/   Normal numbers are unchanged; javaInt 20000000000 is -1474836480,
/   which then fails the calendar checks just as it does in Java.
.aqc.jdate.javaInt:{[number]
  low:number mod 4294967296;
  $[low >= 2147483648; low - 4294967296; low]};

/ applyExponent[number; exponent; negative]
/   number * 10^exponent (or / 10^exponent if negative, dropping the
/   fraction). Stops early once the result is 0 or already too big to be a
/   valid field, so a huge exponent like 1E999 does not loop for long.
/     applyExponent[2;3;0b]   is 2000
/     applyExponent[25;1;1b]  is 2
.aqc.jdate.applyExponent:{[number;exponent;negative]
  i:0;
  while[(i < exponent) and (number > 0) and number < 1000000000000000000;
    number:$[negative; number div 10; number * 10];
    i+:1];
  number};

/ readNumber[txt; i]
/   Read a number at index i the way Java's DecimalFormat does: digits,
/   then optionally "E", an optional "-", and more digits. An "E" without
/   digits after it is not part of the number.
/     readNumber["2020/"; 0]   is `ok`number`next!(1b;2020;4)
/     readNumber["1E3'"; 0]    is `ok`number`next!(1b;1000;3)
/   returns: dictionary; ok is 0b if there is no digit at i
.aqc.jdate.readNumber:{[txt;i]
  stop:.aqc.jdate.skipDigits[txt;i];
  if[stop = i; :`ok`number`next!(0b;0;i)];
  number:"J"$txt i + til stop - i;
  / optional exponent. (Indexing past the end of a string gives " " in q,
  / which is neither "E" nor "-", so no length checks are needed here.)
  if["E" = txt stop;
    negative:"-" = txt stop + 1;
    expStart:stop + 1 + negative;   / a boolean counts as 0 or 1
    expStop:.aqc.jdate.skipDigits[txt;expStart];
    if[expStop > expStart;
      exponent:"J"$txt expStart + til expStop - expStart;
      number:.aqc.jdate.applyExponent[number;exponent;negative];
      stop:expStop]];
  `ok`number`next!(1b;.aqc.jdate.javaInt number;stop)};


/ ---------------------------------------------------------------------------
/ Parsing, checking and printing
/ ---------------------------------------------------------------------------

/ parseFields[pattern; txt]
/   Walk the pattern over the start of txt, like SimpleDateFormat.parse.
/     parseFields[DATE; "1/ 2/2020'"]   is `month`day`year!1 2 2020
/   returns: dictionary from field name to value, or () if txt does not fit
.aqc.jdate.parseFields:{[pattern;txt]
  fields:()!();
  i:0;
  k:0;
  while[k < count pattern;
    step:pattern k;
    $[-11h = type step;
      / a field: skip spaces and tabs, then read a number
      [while[(i < count txt) and txt[i] in " \t"; i+:1];
       r:.aqc.jdate.readNumber[txt;i];
       if[not r`ok; :()];
       fields[step]:r`number;
       i:r`next];
      / a literal character
      [if[(i >= count txt) or step <> txt i; :()];
       i+:1]];
    k+:1];
  fields};

/ isLeapYear[year]
/   Julian rule (every 4th year) before 1582, Gregorian rule from 1582 on.
.aqc.jdate.isLeapYear:{[year]
  $[year < 1582;
    0 = year mod 4;
    (0 = year mod 4) and (0 <> year mod 100) or 0 = year mod 400]};

/ daysInMonth[year; month]
/     daysInMonth[2020;2]   is 29
.aqc.jdate.daysInMonth:{[year;month]
  days:31 28 31 30 31 30 31 31 30 31 30 31;
  days[month - 1] + (month = 2) and .aqc.jdate.isLeapYear year};

/ isValid[fields]
/   Does a dictionary from parseFields hold a real date (and time)?
/     isValid `month`day`year!2 29 2021   is 0b
.aqc.jdate.isValid:{[fields]
  year:fields`year; month:fields`month; day:fields`day;
  if[not year within 1 292278994; :0b];
  if[not month within 1 12; :0b];
  if[not day within 1,.aqc.jdate.daysInMonth[year;month]; :0b];
  / 5-14 October 1582 were skipped when the Gregorian calendar started
  if[(year = 1582) and (month = 10) and day within 5 14; :0b];
  / a date has no time fields; a timestamp has all three
  if[not `hour in key fields; :1b];
  (fields[`hour] within 0 23) and (fields[`minute] within 0 59) and fields[`second] within 0 59};

/ pad[width; number]
/   Leading zeros up to width digits; wider numbers are kept whole.
/     pad[4;3]   is "0003"
.aqc.jdate.pad:{[width;number]
  digits:string number;
  ((0 | width - count digits)#"0"),digits};

/ format[pattern; fields]
/   Print the fields with the pattern.
/     format[DATE; `month`day`year!1 2 3]   is "01/02/0003"
.aqc.jdate.format:{[pattern;fields]
  / each step becomes a string: a padded number, or the literal character
  printStep:{[fields;step]
    $[-11h = type step; .aqc.jdate.pad[$[step = `year; 4; 2]; fields step]; enlist step]};
  raze printStep[fields] each pattern};

/ normalise[pattern; txt]
/   Parse txt with the pattern, check it, and print it back.
/   returns: the re-printed text, or "" if txt is not valid
.aqc.jdate.normalise:{[pattern;txt]
  fields:.aqc.jdate.parseFields[pattern;txt];
  if[0 = count fields; :""];
  if[not .aqc.jdate.isValid fields; :""];
  .aqc.jdate.format[pattern;fields]};

/ normaliseDate[txt]
/     normaliseDate "1/2/2020'"   is "01/02/2020"
/     normaliseDate "2/30/2020"   is ""
.aqc.jdate.normaliseDate:{[txt] .aqc.jdate.normalise[.aqc.jdate.DATE;txt]};

/ normaliseTimestamp[txt]
/     normaliseTimestamp "1/2/2020D1:2:3"   is "01/02/2020D01:02:03"
.aqc.jdate.normaliseTimestamp:{[txt] .aqc.jdate.normalise[.aqc.jdate.TIMESTAMP;txt]};
