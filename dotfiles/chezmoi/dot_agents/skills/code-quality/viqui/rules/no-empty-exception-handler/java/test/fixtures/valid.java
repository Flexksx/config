final class Example {
    void load(String location, boolean ready) {
        if (ready) {
            read(location);
        }
        try {
            read(location);
        } catch (RuntimeException error) {
            report(error);
        }
    }

    void read(String location) {
    }

    void report(RuntimeException error) {
    }
}
