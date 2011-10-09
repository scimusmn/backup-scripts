/**
 * Convert date strings
 * Inspiration from - http://www.ioncannon.net/programming/33/using-strptime-to-parse-iso-8601-formated-timestamps/
 */

#include <string.h>;
#include <stdio.h>;
#include <time.h>;

void convert_iso8601(const char *time_string, int ts_len, struct tm *tm_data)
{
  /*Initialize the timezone functions*/
  tzset();

  /*Set a temp variable with only part of the time string*/
  char temp[64];
  memset(temp, 0, sizeof(temp));
  strncpy(temp, time_string, ts_len);

  /* Setup the time struct with the current time*/
  struct tm ctime;
  memset(&ctime, 0, sizeof(struct tm)); /* Memory handling */

  /* Convert a string to time values with a specific formatting */
  strptime(temp, "%FT%T%z", &ctime);

  long ts = mktime(&ctime) - timezone;
  localtime_r(&ts, tm_data);
}

int main()
{
  /* Turn this into an argument to be submitted */
  char date[] = "2006-03-28T16:49:29.000Z";

  struct tm tm;
  memset(&tm, 0, sizeof(struct tm));
  convert_iso8601(date, sizeof(date), &tm);

  /* Format and print date strings */
  char datestring[128];
  char timestamp[128];
  strftime(datestring, sizeof(datestring), "%a, %d %b %Y %H:%M:%S %Z", &tm);
  printf("Date: %s\n", datestring);
  strftime(timestamp, sizeof(timestamp), "%s", &tm);
  printf("Timestamp: %s\n", timestamp);
}

