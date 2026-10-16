// Comportamentos leves da interface (sem dependências).
(function () {
  // Busca instantânea: filtra as linhas já exibidas na lista (não consulta o banco).
  var campo = document.getElementById("busca");
  var tabela = document.getElementById("tabela");
  if (campo && tabela) {
    campo.addEventListener("input", function () {
      var termo = campo.value.toLowerCase();
      tabela.querySelectorAll("tbody tr").forEach(function (linha) {
        if (linha.querySelector("td.vazio")) return;
        var achou = linha.textContent.toLowerCase().indexOf(termo) !== -1;
        linha.style.display = achou ? "" : "none";
      });
    });
  }

  // Menu "Ações": fecha ao clicar fora ou ao abrir outro.
  document.addEventListener("click", function (e) {
    document.querySelectorAll("details.menu[open]").forEach(function (d) {
      if (!d.contains(e.target)) d.removeAttribute("open");
    });
  });

  // Confirmação antes de decidir um pedido (a decisão não tem "desfazer").
  var formDecisao = document.querySelector("form[data-confirmar-decisao]");
  if (formDecisao) {
    formDecisao.addEventListener("submit", function (e) {
      var decisao = formDecisao.elements["decisao"].value;
      var animal = formDecisao.dataset.animal;
      var pedido = formDecisao.dataset.pedido;
      var texto =
        decisao === "aprovar"
          ? "Aprovar a adoção de " +
            animal +
            " (pedido #" +
            pedido +
            ")?\n\nO animal passará a 'Adotado' e os outros pedidos pendentes dele serão recusados."
          : "Recusar o pedido #" + pedido + " (" + animal + ")?";
      if (
        !window.confirm(
          texto + "\n\nEssa decisão não pode ser desfeita pelo sistema.",
        )
      )
        e.preventDefault();
    });
  }
})();
