#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <arquivo.bin>\n", argv[0]);
        return 1;
    }

    int fd = open(argv[1], O_RDONLY);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    // Obter tamanho do arquivo
    off_t size = lseek(fd, 0, SEEK_END);
    lseek(fd, 0, SEEK_SET);

    // Alocar memória executável
    void *mem = mmap(NULL, size, PROT_READ | PROT_WRITE | PROT_EXEC,
                     MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mem == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return 1;
    }

    // Carregar binário na memória
    if (read(fd, mem, size) != size) {
        perror("read");
        munmap(mem, size);
        close(fd);
        return 1;
    }
    close(fd);

    // Ponteiro para função (entry point no início do binário)
    void (*entry)(void) = (void (*)(void))mem;

    printf("🚀 Executando Rafaelia Monolith diretamente no Linux...\n");
    entry();
    printf("✅ Execução concluída.\n");

    munmap(mem, size);
    return 0;
}
