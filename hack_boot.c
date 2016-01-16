#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(int argc, char *argv[]) {

	int fd;
	int magic = 0xaa55;
	fd = open(argv[1], O_RDWR);
	lseek(fd, 510, 0);
	write(fd, &magic, 2);
	close(fd);
	return 0;
}
