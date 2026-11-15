def work():
    @cache
    def activate():
        return set_state("active")

    activate()
