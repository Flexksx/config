final class Example {
    int choose(boolean ready, boolean fast, int value) {
        return ready ? value : fast ? 1 : 0;
    }
}
