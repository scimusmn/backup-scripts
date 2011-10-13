/**
 * Convert date strings
 * Inspiration from
 * http://www.ioncannon.net/programming/33/using-strptime-to-parse-iso-8601-formated-timestamps/
 */

#include <string.h>;
#include <stdio.h>;
#include <stdlib.h>
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
  strptime(temp, "%Y-%m-%dT%H:%M:%S%z", &ctime);

  long ts = mktime(&ctime);
  /*long ts = mktime(&ctime) - timezone;*/
  localtime_r(&ts, tm_data);
}

int main ( int argc, char *argv[] )
{
  if ( argc != 2 )
  {
    /* Move usage into a usage funciton */
    printf("Usage: %s datestring\n", argv[0]);
  }
  else
  {
    /* Turn this into an argument to be submitted */
    char date[64];
    strcpy(date, argv[1]);
    /*printf("Date arg = %s\n", date);*/

    struct tm tm;
    memset(&tm, 0, sizeof(struct tm));

    if (!strptime(date, "%Y-%m-%dT%H:%M:%S%z", &tm))
    {
      printf("Date format not correct.\n");
      printf("Expects YYYY-MM-DDTHH:MM:SS-#### (-#### = Time zone offset)\n");
      exit (1);
    }
    else
    {
      convert_iso8601(date, sizeof(date), &tm);

      /* Format and print date strings */
      char datestring[128];
      char timestamp[128];
      strftime(datestring, sizeof(datestring), "Day of the week = %a\n \
          Date = %b %d, %Y\n \
          Time = %H:%M:%S", &tm);

      /*printf("%s\n", datestring);*/
      strftime(timestamp, sizeof(timestamp), "%s", &tm);
      printf("%s\n", timestamp);

      /* Print the dates from tm_ variables */
      /*printf("year: %d; month: %d; day: %d;\n", tm.tm_year, tm.tm_mon, tm.tm_mday);*/

      /* Testing args */
      /*printf("Argc = %i\n", argc);*/
      /*printf("Argv 1 = %s\n", argv[1]);*/
    }
  }
}

