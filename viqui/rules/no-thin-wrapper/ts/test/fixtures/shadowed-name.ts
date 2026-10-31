const activate = (id: string) => setState(id, "active");
activate("x");
function other(activate: () => void) {
  use(activate);
}
