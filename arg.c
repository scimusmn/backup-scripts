#include <stdio.h>
#include <time.h>

main(int argc, char *argv[])
{

	printf("arg %d: %s\n", 1, argv[1]);

  struct tm tm;
  time_t epoch;
  if ( strptime(argv[1], "%Y-%m-%d %H:%M:%S", &tm) != NULL )
    epoch = mktime(&tm);
    printf("epoch time = %s\n", epoch)

}

