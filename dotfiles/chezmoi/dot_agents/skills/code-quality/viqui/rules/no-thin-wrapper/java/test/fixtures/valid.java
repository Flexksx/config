final class Example {
    int calc(int value, int factor) {
        return value * factor;
    }

    int scaled(int value) {
        return calc(value, 2);
    }

    int doubled(int value) {
        return calc(value, value);
    }
}
