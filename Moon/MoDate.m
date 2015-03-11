//
//  MoDate.m
//
//
//  Created by Sanjay Madan on 11/13/14.
//  Copyright (c) 2014 mowglii.com. All rights reserved.
//

#import "MoDate.h"

static const NSInteger kDaysInMonth[12] = {
    31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
};

static const NSInteger kMonthDaysSoFar[12] = {
    0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334
};

MoDate MakeDate(NSInteger year, NSInteger month, NSInteger day)
{
    MoDate date;
    date.year = year;
    date.month = month;
    date.day = day;
    date.julian = MakeJulian(year, month, day);
    return date;
}

MoDate MakeDateWithNSDate(NSDate *nsDate, NSCalendar *calendar)
{
    NSInteger year, month, day;
    [calendar getEra:NULL year:&year month:&month day:&day fromDate:nsDate];
    return MakeDate(year, month-1, day);
}

NSDate *MakeNSDateWithDate(MoDate moDate, NSCalendar *calendar)
{
    NSDate *nsDate = [calendar dateWithEra:1 year:moDate.year month:moDate.month+1 day:moDate.day hour:0 minute:0 second:0 nanosecond:0];
    return [calendar startOfDayForDate:nsDate];
}

NSInteger IsValidDate(MoDate date)
{
    return IsValidDate2(date.year, date.month, date.day);
}

NSInteger IsValidDate2(NSInteger year, NSInteger month, NSInteger day)
{
    if  (year  < MIN_MODATE_YEAR ||
         year  > MAX_MODATE_YEAR ||
         month <  0 ||
         month > 11 ||
         day   <  1 ||
         day   > DaysInMonth(year, month)) {
        return 0;
    }
    return 1;
}

NSInteger CompareDates(MoDate date1, MoDate date2)
{
    // -1 => date1 is ealier
    //  1 => date1 is later
    //  0 => dates are the same
    if (date1.julian == NO_JULIAN || date2.julian == NO_JULIAN) {
        return CompareDates2(date1.year, date1.month, date1.day,
                             date2.year, date2.month, date2.day);
    }
    if      (date1.julian < date2.julian) { return -1; }
    else if (date1.julian > date2.julian) { return  1; }
    else                                  { return  0; }
}

NSInteger CompareDates2(NSInteger y1, NSInteger m1, NSInteger d1, NSInteger y2, NSInteger m2, NSInteger d2)
{
    // -1 => date1 is ealier
    //  1 => date1 is later
    //  0 => dates are the same
    if      (y1 < y2) { return -1; }
    else if (y1 > y2) { return  1; }
    else if (m1 < m2) { return -1; }
    else if (m1 > m2) { return  1; }
    else if (d1 < d2) { return -1; }
    else if (d1 > d2) { return  1; }
    else              { return  0; }
}

NSInteger DaysInMonth(NSInteger year, NSInteger month)
{
    return (month == 1 && IS_LEAP_YEAR(year)) ? 29 : kDaysInMonth[month];
}

NSInteger WeeksInYear(NSInteger year)
{
    // How many ISO 8601 weeks are there in a year?
    // A year has 53 weeks if it starts on Thursday -OR-
    // is a leap year and starts on Wednesday.
    // Otherwise, a year has 52 weeks.
    // en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
    
    // First, get the day of the week for January 1.
    // DOW algorithm by Michael Keith and Tom Craver
    // Result is [0..6]; 0=Sunday, 1=Monday...
    // stackoverflow.com/a/21235587/111418
    NSInteger y = year;
    NSInteger m = 1; // January
    NSInteger d = 1;
    NSInteger jan1DOW = (d+=m<3?y--:y-2,23*m/9+d+4+y/4-y/100+y/400)%7;
    
    // Is Jan1 a Thursday OR a Wednesday in a leap year?
    if (jan1DOW == 4 || (jan1DOW == 3 && IS_LEAP_YEAR(year))) {
        return 53;
    }
    return 52;
}

NSInteger WeekOfYear(NSInteger year, NSInteger month, NSInteger day)
{
    // First, calculate the day of the year.
    NSInteger dayOfYear = kMonthDaysSoFar[month] + day;
    if (month > 1 && IS_LEAP_YEAR(year)) {
        dayOfYear += 1;
    }
    // Next, calculate the week number.
    // en.wikipedia.org/wiki/ISO_week_date#Calculation
    NSInteger week = (dayOfYear + 9)/7;
    if (week > WeeksInYear(year)) {
        return 1;
    }
    else if (week < 1) {
        return WeeksInYear(year-1);
    }
    return week;
}

NSInteger MakeJulian(NSInteger year, NSInteger month, NSInteger day)
{
    // Algorithm 199
    // Conversions Between Calendar Date and Julian Day Number
    // Robert G. Tantzen
    // Air Force Missle Development Center, Holloman AFB, New Mexico
    // pmyers.pcug.org.au/IndexedMultipleYearCalendar/Calgo_199.PDF
    
    // Input month is [0..11], algorithm uses [1..12]
    month += 1;
    
    if (month > 2) {
        month -= 3;
    }
    else {
        month += 9;
        year -= 1;
    }
    NSInteger c = year/100;
    NSInteger ya = year - 100*c;
    return 146097*c/4 + 1461*ya/4 + (153*month + 2)/5 + day + 1721119;
}

MoDate MakeGregorian(NSInteger julian)
{
    // Algorithm 199
    // Conversions Between Calendar Date and Julian Day Number
    // Robert G. Tantzen
    // Air Force Missle Development Center, Holloman AFB, New Mexico
    // pmyers.pcug.org.au/IndexedMultipleYearCalendar/Calgo_199.PDF
    
    MoDate result;
    result.julian = julian;
    
    julian -= 1721119;
    NSInteger y = (4*julian - 1)/146097;
    julian = 4*julian - 1 - 146097*y;
    NSInteger d = julian/4;
    julian = (4*d + 3)/1461;
    d = 4*d + 3 - 1461*julian;
    d = (d + 4)/4;
    NSInteger m = (5*d - 3)/153;
    d = 5*d - 3 - 153*m;
    d = (d + 5)/5;
    y = 100*y + julian;
    if (m < 10) {
        m += 3;
    }
    else {
        m -= 9;
        y += 1;
    }
    
    // Algorithm uses months [1..12], CalDate uses [0..11]
    m -= 1;
    
    result.year  = y;
    result.month = m;
    result.day   = d;
    return result;
}

MoDate AddDaysToDate(NSInteger days, MoDate date)
{
    if (date.julian == NO_JULIAN) {
        date.julian = MakeJulian(date.year, date.month, date.day);
    }
    return MakeGregorian(date.julian + days);
}

MoDate AddMonthsToMonth(NSInteger months, MoDate date)
{
    NSInteger newYear  = date.year  + months/12;
    NSInteger newMonth = date.month + months%12;
    if (newMonth > 11) {
        newMonth -= 12;
        newYear  += 1;
    }
    else if (newMonth < 0) {
        newMonth += 12;
        newYear  -= 1;
    }
    return MakeDate(newYear, newMonth, 1);
}

MoMonth MakeMonth(NSInteger year, NSInteger month, NSInteger weekStartDOW)
{
    MoMonth result;
    result.year  = year;
    result.month = month;
    
    // Get the first of the month.
    MoDate firstOfMonth = MakeDate(year, month, 1);

    // Get the DOW for the first of the month.
    // en.wikipedia.org/wiki/Julian_day#Finding_day_of_week_given_Julian_day_number
    NSInteger monthStartDOW = (firstOfMonth.julian + 1)%7;
    
    // On which column [0..6] in the monthly calendar does this date fall?
    NSInteger monthStartColumn = DOW_COL(weekStartDOW, monthStartDOW);

    // Get the date for the first column of the monthly calendar.
    MoDate date = AddDaysToDate(-monthStartColumn, firstOfMonth);
    
    // On which column [0..6] in the monthly calendar does Monday fall?
    NSInteger mondayColumn = DOW_COL(weekStartDOW, 1); // 1=Monday

    // Fill in the calendar grid sequentially.
    for (NSInteger row = 0; row < 6; row++) {
        for (NSInteger col = 0; col < 7; col++) {
            result.dates[row][col] = date;
            // ISO 8601 weeks are defined to start on Monday (and
            // really only make sense if weekStartDOW is Monday).
            // If the current column is Monday, use this date to
            // calculate the week number for this row.
            if (col == mondayColumn) {
                result.weeks[row] = WeekOfYear(date.year, date.month, date.day);
            }
            date = AddDaysToDate(1, date);
        }
    }
    return result;
}