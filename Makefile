sqldriver: sqldriver.asm
        nasm -f elf64 -g -F dwarf sqldriver.asm -o sqldriver.o
        ld sqldriver.o sqldriver
clean:
        rm -f sqldriver.o -o sqldriver
test.sqlite:
        rm -f test.sqlite
        sqlite3 test.sqlite "CREATE TABLE people(id INTEGER PRIMARY KEY,name TEXT,age INTEGER);"
        sqlite3 test.sqlite "INSERT INTO people(name,age) VALUES ('ada',30),('Grace',85);"
.PHONY: clean
