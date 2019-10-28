extensions [matrix distribution]

globals [
  cor1
  cor2
  values-matrix
  pascal-triangle
  colors
  color-option
  VCS
  CS-atual
  other-distribution
  n-of-messages
  aux
  time-to-join
  time-in-coalition
  avg-payoff
  acc-payoff
  agents-info
  avg-agents-out
  avg-time-in-coalition
  avg-time-to-join
  last-CSs
  is-stable?
]

turtles-own [
  changed?
  neighborhood ;todos vizinhos
  neighborhoodG ;somente vizinhos maiores
  inbox
  current-coalition
  coalition-leader
  coalition-value
  coalitions
  ;invitations-sent
  invitations-received
  invitation-selected
  invitations-replies
  final-replies
  coalition-color
  in-coalition?
  last-join-unjoin
  in-loop?
  last-tries
  n-last-tries
  waiting-for-replies?
  has-accepted?
  waiting-final?
  choosen-coalition
  iterations-to-new-join
  accumulated-value
  active-since
]

to setup

  clear-all

  reset-ticks

  set cor1 rgb 230 230 230
  set cor2 rgb 250 250 250

  set-colors
  set color-option 1

  ifelse scenario = "random" [
    setup-turtles
    setup-patches
    setup-links
  ]
  [
    setup-7-agents
  ]

  change-colors
  setup-values

  set is-stable? false

  ;change-colors

end

to set-colors
  set colors []
  set colors n-values 140 [?]
  foreach n-values 13 [(? + 1) * 10] [
    set colors remove ? colors
  ]
  set colors shuffle colors
end

to setup-7-agents

  set n-of-agents 7

  set-default-shape turtles "circle"
  crt n-of-agents
  ask turtle 0 [
    set xcor -6
    set ycor -2
    set neighborhood (list (turtle 1) (turtle 2) (turtle 3) (turtle 4) (turtle 5) (turtle 6))
    set neighborhoodG (list (turtle 1) (turtle 2) (turtle 3) (turtle 4) (turtle 5) (turtle 6))
  ]
  ask turtle 1 [
    set xcor -5
    set ycor 3
    set neighborhood (list (turtle 0) (turtle 2) (turtle 3) (turtle 4) (turtle 5) (turtle 6))
    ;set neighborhood (list (turtle 0) (turtle 3) (turtle 4) (turtle 5) (turtle 6))
    set neighborhoodG (list (turtle 2) (turtle 3) (turtle 4) (turtle 5) (turtle 6))
  ]
  ask turtle 2 [
    set xcor 0
    set ycor 6
    set neighborhood (list (turtle 0) (turtle 1) (turtle 5) (turtle 6))
    ;set neighborhood (list (turtle 0) (turtle 5) (turtle 6))
    set neighborhoodG (list (turtle 5) (turtle 6))
  ]
  ask turtle 3 [
    set xcor 5
    set ycor 3
    set neighborhood (list (turtle 0) (turtle 1) (turtle 4) (turtle 5) (turtle 6))
    set neighborhoodG (list (turtle 4) (turtle 5) (turtle 6))
  ]
  ask turtle 4 [
    set xcor 6
    set ycor -2
    set neighborhood (list (turtle 0) (turtle 1) (turtle 3) (turtle 6))
    set neighborhoodG (list (turtle 6))
  ]
  ask turtle 5 [
    set xcor 3
    set ycor -6
    set neighborhood (list (turtle 0) (turtle 1) (turtle 2) (turtle 3) (turtle 6))
    set neighborhoodG (list (turtle 6))
  ]
  ask turtle 6 [
    set xcor -3
    set ycor -6
    set neighborhood (list (turtle 0) (turtle 1) (turtle 2) (turtle 3) (turtle 4) (turtle 5))
    set neighborhoodG []
  ]
  ask turtles [
    set color blue
    set changed? true
    set inbox []
    set coalitions []
    set coalition-color (item who colors)
    set coalition-leader who
    set current-coalition (list (who + 1))
    ;set invitations-sent []
    set invitations-received []
    set final-replies []
    set invitation-selected []
    set invitations-replies []
    set in-coalition? false
    set last-join-unjoin 0
    set in-loop? false
    set last-tries []
    set n-last-tries 0
    set waiting-for-replies? false
    set has-accepted? false
    set waiting-final? false
    set choosen-coalition []
    set iterations-to-new-join 0
    set accumulated-value 0
    set active-since 0
    let n []
    let nG []
    let tx xcor
    let ty ycor
    ;adiciona a cada agente um label centralizado com seu número
    ifelse who > 8
      [ set label word (who + 1) "  "]
      [ set label word (who + 1) "   "]
    ;cria links entre agentes que podem formar coalizão
    create-links-with other turtles with [self > myself and member? myself neighborhood] [ set color gray ]
  ]

  setup-patches

end

to change-colors
  ifelse color-option = 1
    [ set color-option 2 ]
    [ set color-option 1 ]
  ask turtles [
    ifelse color-option = 1 [;turles na cor azul
      set color blue
      set label-color white
    ]
    [;turtles na cor da coalizão
      set color (item coalition-leader colors)
      ifelse color mod 10 <= 3
        [ set label-color white ]
        [ set label-color black ]
      ;set label-color black
    ]
  ]
end

to setup-values
  ;Gera o triângulo de Pascal
  generatePascalTriangle

  ;set pascal-triangle matrix:from-column-list n-values n-of-agents [n-values n-of-agents [0]]
  ;matrix:set pascal-triangle l c ((matrix:get pascal-triangle (l - 1) c) + (matrix:get pascal-triangle l (c - 1)))

  ;Gera matriz de distribuição de valores das coalizões
  set values-matrix []
  ifelse (is-number? (position "file" distribution)) or distribution = "other" [
    let dir ""
    if distribution = "fileNormal" [ set dir "normal" ]
    if distribution = "fileNormal80" [ set dir "normal80" ]
    if distribution = "fileV2G1" [ set dir "V2G1" ]
    ifelse distribution = "other"
      [ file-open other-distribution ]
      [ file-open (word "distributions//" dir "//" (n-of-agents + 5) "agents.txt") ]

    let s-atual 0
    let CLs (list -1)
    while [ not file-at-end? ] [
      let str file-read-line
      let s item 0 read-from-string str ;s
      let id item 1 read-from-string str ;id
      let v item 2 read-from-string str ;v(C)
      if s != s-atual [
        set values-matrix lput CLs values-matrix
        set CLs (list -1);para facilitar o tratamento pelo id, é criado um elemento para o id0
        set s-atual s
      ]
      set CLs lput v CLs
    ]
    set values-matrix lput CLs values-matrix
    file-close
  ]
  [
    if distribution != "distributionExt" [
      let CLs (list -1)
      set values-matrix lput CLs values-matrix
      foreach n-values n-of-agents [? + 1] [
        let s ?
        set CLs (list -1)
        foreach n-values (getCoalitionListSize n-of-agents s) [? + 1] [
          ifelse distribution = "uniform"
          [ set CLs lput (genValueDistUniform s) CLs ]
          [
            ifelse distribution = "normal"
              [ set CLs lput (genValueDistNormal s) CLs ]
              [ set CLs lput (genValueDistCardinality s) CLs ]
          ]
        ]
        set values-matrix lput CLs values-matrix
      ]
    ]
  ]


  ;Calcula o valor inicial de cada coalizão
  ask turtles [
    set coalition-value (getCoalitionValue (list (who + 1)))
  ]
end

to setup-turtles
  set-default-shape turtles "circle"
  ask n-of n-of-agents patches [
    sprout 1 [
      set color blue
      set changed? true
      set neighborhood []
      set neighborhoodG []
      set inbox []
      set coalitions []
      set coalition-color (item who colors)
      set coalition-leader who
      set current-coalition (list (who + 1))
      ;set invitations-sent []
      set invitations-received []
      set final-replies []
      set invitation-selected []
      set invitations-replies []
      set in-coalition? false
      set last-join-unjoin 0
      set in-loop? false
      set last-tries []
      set n-last-tries 0
      set waiting-for-replies? false
      set has-accepted? false
      set waiting-final? false
      set choosen-coalition []
      set iterations-to-new-join 0
      set accumulated-value 0
      set active-since 0
      ;adiciona a cada agente um label centralizado com seu número
      ifelse who > 8
        [ set label word (who + 1) "  "]
        [ set label word (who + 1) "   "]
      new-agents-stat-info
    ]
  ]
end

to setup-patches
  ask patches [
    ;patches em xadrez
    ifelse ((pxcor mod 2 = 0) and (pxcor mod 2 = 0 and pycor mod 2 = 0)) or ((pxcor mod 2 = 1) and (pxcor mod 2 != 0 and pycor mod 2 != 0))
     [ set pcolor cor1 ]
     [ set pcolor cor2 ]
  ]
end

to setup-links
  ask turtles [
    let n []
    let nG []
    let tx xcor
    let ty ycor

    ;cria links entre agentes que podem formar coalizão
    create-links-with other turtles with [sqrt (((xcor - tx) ^ 2) + ((ycor - ty) ^ 2)) < alpha] [ set color gray ]

    ;monta lista de vizinhos
    ask my-links with [ color = gray ] [
      if myself < other-end
        [ set nG lput other-end nG ]
      set n lput other-end n
    ]
    set neighborhood sort-by < n
    set neighborhoodG sort-by < nG
  ]
end

to go

  ;reset-timer

  ;lê mensagens recebidas
  read-messages

  ask turtles with [iterations-to-new-join > 0] [set iterations-to-new-join iterations-to-new-join - 1]

  ;
  process-final

  ;processa as respostas a convites
  process-replies

  ;#### sempre que tiver convites ele responde. se tiver uma resposta e a coalizão for formada, responde não a todos os convites com resposta 3=nao
  ;processa os convites recebidos
  process-invitations

  ;convida vizinhos
  verify-neighbors;optei por tentar verificar os vizinhos apenas se não tiver convites e se eu não estiver em uma coalizão

  do-statistics

  ;atualiza os gráficos
  do-plots

  tick

  ;print timer

end

to do-statistics

  ;calcula o payoff instantâneo de cada agente
  calculate-instant-payoff

  ;calculate-acc-payoff
  ;set acc-payoff acc-payoff + (VCS / 60)

  ask turtles [
    ifelse in-coalition?
      [ set-agents-stat-info who 3 0 ]
      [ set-agents-stat-info who 4 0 ]
  ]

end

to count-messages
  set n-of-messages 0
  ask turtles [
    set n-of-messages n-of-messages + length inbox
  ]
end

to go-forever-exp
  while [ticks < max-ticks and (open-world? or (not open-world? and is-there-working-agents?))] [
    go-forever
  ]
end

to go-forever
  if open-world? [
    ;if random-float 1 < p_e and n-of-agents < 127[
    ;  create-new-agent
    ;]

    if random-float 1 < p_l and n-of-agents > 2 and ticks > 3 [
      kill-agent
      create-new-agent
     ]
   ]

   go

   if slow-ticks = true [
     wait interval
   ]
end

to go-n-times
  let solutions []
  let time 1
  while [time <= repetitions] [
    show "-------------------------------------------------"
    show time
    show "-------------------------------------------------"
    reset-graph
    reset-timer
    while [ticks < max-ticks and is-there-working-agents?] [
      go-forever
    ]

    set solutions lput (list (timer * 1000) CS-atual VCS) solutions
    set time time + 1
  ]

  show "Time(ms);CS;V(CS)"
  let i item 2 (item 0 solutions)
  foreach solutions [
    show processa-string (word (item 0 ?) ";" (item 1 ?) ";" (item 2 ?))
    if i != item 2 ? [
      set i -999
    ]
  ]
  ifelse i = -999
    [ show "Há divergências!" ]
    [ show "certo" ]
end

to-report go-n-times-exp
  let time 1

  let sum-time 0
  let sum-vcs 0

  while [time <= repetitions] [
    reset-graph
    reset-timer
    go-forever-exp

    set sum-time sum-time + (timer * 1000)
    set sum-vcs sum-vcs + VCS

    set time time + 1
  ]
  set sum-time sum-time / repetitions
  set sum-vcs sum-vcs / repetitions
  report processa-string (word sum-time ";" sum-vcs)

end

to process-final
  ask turtles with [waiting-final? ][;and not empty? invitation-selected ] [

    if length final-replies > 0 [
      ifelse not empty? invitation-selected [

        let meA who
        let accepted []

        foreach final-replies [
          if item 2 ? = 1 [
            set accepted lput ((item 0 ?) + 1) accepted
          ]
        ]

        ifelse not empty? accepted [

          let newCoalition union current-coalition accepted
          let vC getCoalitionValue newCoalition
          ;show-monitoring who (word "new = " newCoalition)

          foreach newCoalition [

            if is-turtle? (turtle (? - 1)) [
              ask turtle (? - 1) [
                ;define o líder
                set coalition-leader meA
                set current-coalition sort-by < newCoalition

                ;atualiza o valor da coalizão
                set coalition-value vC

                ;atualiza a cor da coalizão
                set coalition-color (item coalition-leader colors)
                if color-option = 2 [
                  set color coalition-color
                  ifelse color mod 10 <= 3
                  [ set label-color white ]
                  [ set label-color black ]
                ]

                ;bloqueia o ingresso em outras coalizões
                ;set iterations-to-new-join 30

                set waiting-final? false
                set invitation-selected []
                set choosen-coalition []
                set in-coalition? true
                set waiting-for-replies? false
                set has-accepted? false
                set time-to-join lput (ticks - last-join-unjoin) time-to-join
                set last-join-unjoin ticks
              ]
            ]

          ]
        ]
        [
          set waiting-final? false
          set invitation-selected []
          set choosen-coalition []
          set waiting-for-replies? false
          set has-accepted? false
        ]
      ]
      [
        foreach final-replies [
          if item 2 ? = 1 [
            ask turtle ((item 0 ?)) [
              set waiting-final? false
              set invitation-selected []
              set choosen-coalition []
              set in-coalition? false
              set waiting-for-replies? false
              set has-accepted? false
            ]
          ]
        ]

      ]
    ]
  ]
end

to process-replies
  ask turtles with [waiting-for-replies? = true] [
    ifelse length invitations-replies > 0 [
      ;show "Processing replies!"
      set waiting-for-replies? false

      let accept? false
      let reject? false

      let rem item 0 (first invitations-replies)
      let C item 1 (first invitations-replies)
      let resp item 2 (first invitations-replies)

      ifelse not in-coalition? [
        ifelse not empty? invitation-selected [;rem c resp

          let vC getCoalitionValue C
          let vCsel getCoalitionValue invitation-selected

          ifelse invitation-selected = C [
            ifelse who > rem [
              set accept? true
              set invitation-selected []
            ]
            [
              ;set reject? true
            ]
            set waiting-final? true
          ]
          [
            ifelse vC > vCSel [
              set accept? true
              set invitation-selected []
            ]
            [
              set reject? true
            ]

            set waiting-final? true
          ]

        ]
        [
          ifelse resp = 1 [
            set accept? true
            set waiting-final? true
          ]
          [
            ;nada
            ;set waiting-for-replies? false
          ]

        ]
      ]
      [
        set reject? true
      ]

      if accept? [
        show-monitoring who (word "[3]Aceitou " C)
        ;if who = 13 [show "aqui"]
        set has-accepted? true;não serve para nada
        ;confirma o interesse
        let msg (list 5 who C 1);[tipo remetente coalition resposta]
        ask turtle rem [
            set inbox lput msg inbox
        ]

      ]

      if reject? [
        show-monitoring who (word "[3]Cancelou " C)
        ;cancela o interesse
        let msg (list 5 who C 2);[tipo remetente coalition resposta]
        ask turtle rem [
            set inbox lput msg inbox
        ]
      ]

    ]
    [

    ]
  ]
end

to process-replies_JBCS
  ;verifica apenas se o agente estiver aguardando por respostas e se tiver alguma resposta
  ask turtles with [waiting-for-replies? = true] [

    ifelse length invitations-replies > 0 [

      let leader who

      set waiting-for-replies? false

      ;verifica se alguém não aceitou
      let nao []
      foreach invitations-replies [
        let rem item 0 ?
        let resp item 2 ?
        if resp = 2 [ ;NÃO - se alguém disse não, remove o vizinho de todas as coalizões potenciais e tenta novamente sem o mesmo
                      ;(só diz não quem já aceitou participar de uma coalizão ou quem recebeu uma oferta melhor)
                      ;(remove todos porque se o vizinho não aceitou a melhor oferta que eu posso fazer a ele, ele não aceitará nenhuma outra)
          set nao lput rem nao
          ;show (word rem " não aceitou!")
        ]
      ]
      ;apaga lista
      set invitations-replies []
      ;if who = 2 [show nao]
      ifelse not empty? nao [ ;se algum vizinho não aceitou, remove ele de todas coalizões potenciais

        let newCoalitions []
        ;show coalitions
        foreach coalitions [
          let c item 0 ?
          foreach nao [
            set c remove (? + 1) c
          ]
          if length c > 1
          [ set newCoalitions lput (list c (getCoalitionValue c)) newCoalitions ]
        ]
        ;show newCoalitions
        ;ordena as coalizões pelo valor
        set coalitions (sort-by [ (last ?1) > (last ?2) ] newCoalitions)
        ;show coalitions

        ;envia mensagem de cancelamento
        let msg (list 3 leader);[tipo leader-agent]
        foreach choosen-coalition [
          if (? - 1) != leader [
            if is-turtle? (turtle (? - 1)) [
              ask turtle (? - 1) [
                set inbox lput msg inbox
              ]
            ]
          ]
        ]

        set invitation-selected []
        set choosen-coalition []
        ;if who = 2 [show coalitions]
        ;das coalizões que sobraram, escolhe a melhor e convida os vizinhos novamente
        if not empty? coalitions [
          invite-neighbors
        ]
        ;if who = 2 [show coalitions]

      ]
      [ ;se todos aceitaram, concretiza a coalizão
        let vC getCoalitionValue choosen-coalition
        let CC choosen-coalition
        ;para cada membro da coalizão...
        foreach choosen-coalition [
          if is-turtle? (turtle (? - 1)) [
            ask turtle (? - 1) [
              ;define o líder
              set coalition-leader leader
              set current-coalition CC

              ;atualiza o valor da coalizão
              set coalition-value vC

              ;atualiza a cor da coalizão
              set coalition-color (item coalition-leader colors)
              if color-option = 2 [
                set color coalition-color
                ifelse color mod 10 <= 3
                [ set label-color white ]
                [ set label-color black ]
              ]

              ;bloqueia o ingresso em outras coalizões
              set iterations-to-new-join 30

              set invitation-selected []
              set choosen-coalition []
              set in-coalition? true
              set time-to-join lput (ticks - last-join-unjoin) time-to-join
              set last-join-unjoin ticks

            ]
          ]
        ]
      ]

      ;TEMPORÁRIO
      ;set coalitions []
    ]
    [
      ;set waiting-for-replies? false
    ]
  ]
end

to-report numbers2turtles [numbers]
  let agents []
  foreach numbers [
    set agents lput turtle (? - 1) agents
  ]
  report agents
end

to-report turtles2numbers [turtles-list]
  let numbers []
  foreach turtles-list [
    ask ? [
      set numbers lput (who + 1) numbers
    ]
  ]
  report numbers
end

to-report are-neighbours? [agents]
  let neighbours? true
  let lv agents
  if not is-turtle? first lv
    [ set lv numbers2turtles lv ]
  foreach n-values ((length lv) - 1) [?] [
    let x1 ?
    let ag1 item x1 lv
    foreach n-values ((length lv) - x1 - 1) [? + x1 + 1] [
      let x2 ?
      let ag2 item x2 lv
      ask ag1 [
        if not member? ag2 neighborhood [
          set neighbours? false;set vizinhos? false
        ]
      ]
    ]
  ]
  report neighbours?
end

to process-invitations
  ask turtles with [length invitations-received > 0] [
    ;if ticks = 5 and who = 13 [ show has-accepted? ]
    ifelse empty? invitation-selected [

      ;show "Processing invitations!"
      let meA who
      let accepted false
      let acceptDirect false

      let newTurtles []
      let newCoalition []

      let lv []
      foreach invitations-received [
        set lv lput ((first ?) + 1) lv
      ]
      show-monitoring who (word "lv = " lv)

      if not waiting-final? [
        if true [;not has-accepted? [;not waiting-for-replies? [;FEITO    has-accepted?
          ;agente que recebeu o pedido está em uma coalizão
          ifelse in-coalition? [
            ;show "está em uma coalizão"
            ;apenas um pedido
            ifelse length invitations-received = 1 [
              set newCoalition sort-by < (union current-coalition (first (first invitations-received) + 1))
              if is-feasible? newCoalition [
                set accepted true
                set acceptDirect true
              ]
              ;show newCoalition
            ]
            [
              ;todos que pediram são vizinhos
              ifelse are-neighbours? lv [
                ;show "AGORA SIM!"
                set newTurtles numbers2turtles minus lv (meA + 1)
                set newCoalition sort-by < union current-coalition minus lv (meA + 1)

                if is-feasible? newCoalition [
                  set accepted true
                  set acceptDirect true
                ]
                ;show newCoalition
              ]
              ;NEM todos que pediram são vizinhos
              [
                ;show "NEM TODOS"
                let bestFeasible minus (get-best-coalition get-feasible-coalitions (meA + 1) lv) (meA + 1)
                ;show bestFeasible
                set newTurtles numbers2turtles bestFeasible;minus bestFeasible meA
                set newCoalition sort-by < union current-coalition bestFeasible
                ;show newCoalition
                if is-feasible? newCoalition [
                  set accepted true
                  set acceptDirect true
                ]
              ]
            ]
          ]
          ;agente que recebeu o pedido NÃO está em uma coalizão
          [
            if length choosen-coalition < 3 [
              ;apenas um pedido
              ifelse length invitations-received = 1 [
                ;convite mútuo
                ifelse item 1 (first invitations-received) = choosen-coalition [
                  ;se o agente for o de menor ID aceita (ele será o líder)
                  ifelse meA < first (first invitations-received) [
                    set newTurtles lput (turtle first (first invitations-received)) newTurtles
                    set newCoalition sort-by < (list (meA + 1) (first (first invitations-received) + 1))
                    if is-feasible? newCoalition [
                      set accepted true
                    ]
                  ]
                  ;se o agente não for o de menor ID, não faz nada (pois o líder é quem aceitará)
                  [
                    ;não faz nada
                    ;show "não"
                  ]
                ]
                [
                  ;se o convite não for mútuo, rejeita
                  ;show "rejeita"
                  ;set accepted true
                ]
              ]
              ;múltiplos pedidos
              [
                ;todos que pediram são vizinhos
                ifelse are-neighbours? lv [
                  set newTurtles numbers2turtles minus lv (meA + 1)
                  set newCoalition sort-by < union current-coalition minus lv (meA + 1)
                  if is-feasible? newCoalition [
                    set accepted true
                  ]
                ]
                ;NEM todos que pediram são vizinhos
                [
                  ;show "não está em uma coalizão e recebeu múltiplos pedidos de agentes que não são vizinhos entre si"
                  let bestFeasible minus (get-best-coalition get-feasible-coalitions (meA + 1) lv) (meA + 1)
                  ;show bestFeasible
                  set newTurtles numbers2turtles bestFeasible;minus bestFeasible meA
                  set newCoalition sort-by < union current-coalition bestFeasible

                  if is-feasible? newCoalition [
                    set accepted true
                  ]
                ]
              ]
            ]
          ]
          ;show accepted
          ;if accepted [ show (word current-coalition " + " newTurtles " = " newCoalition) ]
        ]
      ]

      ;aceitou pedidos (avisos de sim e não)
      ifelse accepted [

        ;em alguns casos, aceita direto sem precisar trocar mensagens
        ifelse acceptDirect [
          ;show "ACEITO DIRETO!"

          let vC getCoalitionValue newCoalition
          foreach newCoalition [
            if is-turtle? (turtle (? - 1)) [
              ask turtle (? - 1) [
                ;define o líder
                set coalition-leader meA
                set current-coalition newCoalition

                ;atualiza o valor da coalizão
                set coalition-value vC

                ;atualiza a cor da coalizão
                set coalition-color (item coalition-leader colors)
                if color-option = 2 [
                  set color coalition-color
                  ifelse color mod 10 <= 3
                  [ set label-color white ]
                  [ set label-color black ]
                ]

                ;bloqueia o ingresso em outras coalizões
                ;set iterations-to-new-join 30

                set waiting-final? false
                set invitation-selected []
                set choosen-coalition []
                set in-coalition? true
                set waiting-for-replies? false
                set has-accepted? false
                set time-to-join lput (ticks - last-join-unjoin) time-to-join
                set last-join-unjoin ticks
              ]
            ]
          ]

          ;envia o não para os os agentes não aceitos
          let msg (list 2 who [] 2);[tipo remetente coalition resposta]
          foreach minus (numbers2turtles lv) newTurtles [
            ask ? [
              set inbox lput msg inbox
            ]
          ]

        ]
        ;em outros casos, a troca de mensagens é necessária
        [

          ;envia sim para os que foram aceitos ...
          let msg (list 2 who newCoalition 1);[tipo remetente coalition resposta]
          foreach newTurtles [
            ask ? [
              set inbox lput msg inbox
            ]
          ]

          ;... e não para os os demais
          set msg (list 2 who [] 2);[tipo remetente coalition resposta]
          foreach minus (numbers2turtles lv) newTurtles [
            ask ? [
              set inbox lput msg inbox
            ]
          ]

          ;registra o convite respondido, para tratamento posterior
          set invitation-selected newCoalition

          set waiting-final? true;E AGORA?

        ]

      ]
      ;não aceitou (rejeita todos)
      [
        ;show "não aceitou!"
        let msg (list 2 who [] 2);[tipo remetente coalition resposta]
        foreach numbers2turtles lv [
          ask ? [
            set inbox lput msg inbox
          ]
        ]
      ]
    ]
    [
      let msg (list 2 who [] 2);[tipo remetente coalition resposta]
      foreach invitations-received [
        ask turtle (first ?) [
          set inbox lput msg inbox
        ]
      ]
    ]
  ]
end

to process-invitations_2
  ask turtles with [length invitations-received > 0] [

    let meA who
    ;show meA
    ;let toAccept []
    let accepted false
    let newCoalition []

    ;TÁ "FUNCIONANDO"
    ;PROBLEMA: NO INÍCIO, TODOS AGENTES ESTÃO SEPARADOS. INCONSISTÊNCIAS OCORREM
    ;SOLUÇÃO POSSÍVEL 1: MENSAGEM DE RESPOSTA (PODE ENTRAR OU NÃO), E ENTRAM SÓ OS QUE QUISEREM
    ;SOLUÇÃO POSSÍVEL 2: AJUSTA O PROCESSO INICIAL PARA NÃO PRECISAR DE MAIS MENSAGENS

    ifelse length invitations-received = 1 [

      ;agente está numa coalizão e recebe apenas um convite
      ifelse in-coalition? [;not waiting-for-replies? [
        set accepted true
        set newCoalition item 1 (first invitations-received)
      ]
      [
        ;convites mútuos
        ;agente não está numa coalizão e recebe apenas um convite (aceita apenas se for para a mesma coalizão que ele já estava planejando)
        ifelse item 1 (first invitations-received) = choosen-coalition and first (first invitations-received) < meA [
          ;set toAccept item 1 invitations-received
          set accepted true
          set newCoalition item 1 (first invitations-received)

        ]
        [
          ;NÃO FAZ NADA?
          ;(não precisa responder, mas talvez deva limpar as flags)
        ]
      ]

    ]
    [
      ;verifica se os agentes que enviaram pedidos de ingresso são vizinhos entre si
      let vizinhos? true
      let lv []
      foreach invitations-received [
        set lv lput (turtle (first ?)) lv
      ]
      ;show lv
      foreach n-values ((length lv) - 1) [?] [
        let x1 ?
        let ag1 item x1 lv
        foreach n-values ((length lv) - x1 - 1) [? + x1 + 1] [
          let x2 ?
          let ag2 item x2 lv
          ask ag1 [
            if not member? ag2 neighborhood [
              set vizinhos? false
            ]
          ]
        ]
      ]
      ;são vizinhos?
      ifelse vizinhos? [
        set accepted true
        set newCoalition current-coalition
        foreach coalitionName2coalitionNumber lv [
          set newCoalition lput ? newCoalition
        ]
        set newCoalition sort-by < newCoalition
      ]
      [
        ;show "NÃO SÃO VIZINHOS..."
      ]
    ]

    ;aceitar os que estão em toAccept
    if accepted [
      let vC getCoalitionValue newCoalition
      foreach newCoalition [
        if is-turtle? (turtle (? - 1)) [
          ask turtle (? - 1) [

            ;define o líder
            set coalition-leader meA
            set current-coalition newCoalition

            ;atualiza o valor da coalizão
            set coalition-value vC

            ;atualiza a cor da coalizão
            set coalition-color (item coalition-leader colors)
            if color-option = 2 [
              set color coalition-color
              ifelse color mod 10 <= 3
              [ set label-color white ]
              [ set label-color black ]
            ]

            ;bloqueia o ingresso em outras coalizões
            ;set iterations-to-new-join 30

            set invitation-selected []
            set choosen-coalition []
            set in-coalition? true
            set waiting-for-replies? false
            set time-to-join lput (ticks - last-join-unjoin) time-to-join
            set last-join-unjoin ticks

          ]
        ]
      ]
    ]

    ;rejeitar os que não estão em toAccept

  ]
end

to process-invitations_JBCS
  ;apenas agentes que tenham recebido algum convite
  ask turtles with [length invitations-received > 0] [

    let reject-all false

    ;respeita um número mínimo de iterações antes de poder ingressar em uma nova coalizão
    ifelse iterations-to-new-join < 1 [
      ;ordena os convites por valor da coalizão (DESC) e por coalition-leader (ASC), assim a melhor coalizão fica no topo e, se houver mais de um convite para a mesma coalizão,
      ;o convite do agente de menor ID fica no topo
      set invitations-received (sort-by [ (last ?1) > (last ?2) or (((last ?1) = (last ?2)) and ((first ?1) < (first ?2))) ] invitations-received)

      ;escolhe o melhor convite
      let best item 0 invitations-received

      ;separa informações do convite
      let leader item 0 best
      let c item 1 best
      let vC item 2 best

      let accept false

      ;se estiver esperando respostas, o agente não analisa convites
      ;a menos que o convite seja para formar a mesma coalizão que ele já está esperando respostas
      ;se este for o caso, o agente só responde ao convite do agente de menor ID. Exemplo:
      ;os agentes 1, 3 e 5 acham a coalizão {1,3,5} e convidam uns aos outros para participar da mesma,
      ;entratanto, na etapa de processamento de convites, os agentes 3 e 5 cancelam seus convites e respondem SIM ao agente 1, que é o de menor ID.
      ;obs.: os agentes 3 e 5 não enviam mensagem de cancelamento, apenas deixam de aguardar por respostas, já que os demais agentes vão responder apenas ao agente 1 também
      ;show invitations-received
      ifelse waiting-for-replies? = true [
        ifelse c = choosen-coalition or (length coalitions > 0 and (vC > (item 1 (first coalitions)) and (sort-by < lput (leader + 1) choosen-coalition) = c)) [
          ;----------------------------------
          let toRemove []
          foreach invitations-received [
            if item 1 ? = c and ((who = (first c - 1)) or (who > (first c - 1) and (item 0 ? > (first c - 1)))) [
              set toRemove lput ? toRemove
            ]
          ]
          foreach toRemove [
            set invitations-received remove ? invitations-received
          ]
          if not empty? invitations-received and item 1 (first invitations-received) = c [
            set accept true
            set waiting-for-replies? false
            set coalitions []
          ]
          ;show (word "new " invitations-received)
          set reject-all true
        ]
        [
          set reject-all true
        ]
      ]
      [
        ;se o agente já tiver aceito um convite na iteração anterior E receber um convite para a mesma coalizão, porém de um leader diferente, na iteração atual,
        ;ele deve aceitar sempre o convite do agente de menor ID. Isto evita deadlocks.
        ifelse length invitation-selected > 0 and c = (item 1 invitation-selected) and leader < (item 0 invitation-selected) [
          set accept true
        ]
        [
          ;se a coalizão do convite tiver um valor maior que a sua, aceita
          if (vC > coalition-value) [
            set accept true
          ]
        ]
      ]
      ;set waiting-for-replies? false

      ifelse accept = true [
        ;responde SIM para o melhor convite
        ;show (word "accept " c)
        let msg (list 2 who c 1);[tipo remetente coalition resposta]
        ask turtle leader [
          set inbox lput msg inbox
        ]

        ;se já faz parte de uma coalizão, avisa o coalition-leader que está saindo
        if in-coalition? [
          set msg (list 4 who);[tipo remetente]
          if is-turtle? (turtle coalition-leader) [
            ask turtle coalition-leader [
              set inbox lput msg inbox
            ]
          ]
        ]

        ;registra o convite respondido, para tratamento posterior
        set invitation-selected best

        ;remove o convite selecionado da lista
        set invitations-received remove-item 0 invitations-received

        ;rejeita os demais convites
        set reject-all true
      ]
      [
        set reject-all true
      ]

    ]
    [
      set reject-all true
    ]

    if reject-all = true [
      foreach invitations-received [
        ;separa informações do convite
        let leader item 0 ?
        let c item 1 ?

        ;responde NÃO
        let msg (list 2 who c 2);[tipo remetente coalition resposta]

        ask turtle leader [
          set inbox lput msg inbox
        ]

      ]
      set invitations-received []
    ]

  ]
end

to read-messages
  ;lê mensagens as mensagens da caixa de entrada dos agentes, apagando-as em seguida
  ask turtles [
    set invitations-received []
    set invitations-replies []
    set final-replies []
    if not empty? inbox [
      show-monitoring who (word "Inbox: " inbox)
      foreach inbox [
        let tp first ? ;tipo de mensagem
        if tp = 1 [ ;convite
          let la item 1 ? ;leader-agent
          let c item 2 ? ;coalition
          let vC item 3 ? ;coalition-value

          set invitations-received lput (list la c vC) invitations-received
        ]
        if tp = 2 [ ;resposta
          let rem item 1 ? ;remetente
          let c item 2 ? ;coalition
          let resp item 3 ? ;resposta (1=sim, 2=não)

                            ;show (word "O agente " rem " aceitou participar da coalizão " c)

          set invitations-replies lput (list rem c resp) invitations-replies

        ]
        if tp = 3 [ ;cancelamento de convite
          if not empty? invitation-selected [
            if (item 1 ?) = (item 1 invitation-selected) [
              ;remove o convite selecionado da lista
              set invitation-selected []
            ]
          ]
        ]
        if tp = 4 [ ;coalizão desmanchada
          let rem item 1 ? ;remetente

                           ;TODO if rem in my-coalition
                           ;se o remetente faz parte da minha coalizão e se eu s
                           ;if member? (rem + 1) current-coalition and coalition-leader = who [
                           ;]

                           ;ifelse coalition-leader = rem [
                           ;  ;reseta/sai
                           ;]
                           ;[
          if member? (rem + 1) current-coalition and coalition-leader = who [
            let me who
            foreach current-coalition [
              if ? != (rem + 1) and is-turtle? (turtle (? - 1)) [
                ask turtle (? - 1) [
                  if coalition-leader = me [
                    set current-coalition (list (who + 1))
                    set coalition-value getCoalitionValue current-coalition
                    set coalition-leader who
                    set coalition-color (item who colors)
                    set in-coalition? false
                    set time-in-coalition lput (ticks - last-join-unjoin) time-in-coalition
                    set last-join-unjoin ticks
                    set color (item coalition-leader colors)
                  ]
                ]
              ]
            ]
          ]
          ;]

          if not empty? invitation-selected [
            if (item 1 ?) = (item 1 invitation-selected) [
              ;remove o convite selecionado da lista
              set invitation-selected []
            ]
          ]
        ]
        if tp = 5 [
          let rem item 1 ? ;remetente
          let c item 2 ? ;coalition
          let resp item 3 ? ;resposta (1=sim, 2=não)
          set final-replies lput (list rem c resp) final-replies
        ]
      ]
      set inbox []
    ]
  ]
end

to verify-neighbors

  ;meA - Para cada agente
  ask turtles [

    ;este procedimento é realizado apenas pelos agentes que:
    ;    não estão em uma coalizão
    ;    não aceitaram nenhum convite (ou seja, que não estão no processo de ingresso em uma coalizão)
    ;    não estão aguardando resposta de outros agentes
    if in-coalition? = false and empty? invitation-selected and waiting-for-replies? = false and waiting-final? = false[
      ;show "Finding new coalitions..."
      ;TEMPORÁRIO
      set coalitions []
      set choosen-coalition []

      let meWho who + 1
      let meA self
      let neighborhoodA neighborhood
      let matrizCoalizoesParesAB []

      let nToConsider []
      ifelse optimize-potential-coalition-generation [
        let ntemp []
        if not empty? neighborhood [
          ask first neighborhood [ set ntemp neighborhood ]
          foreach neighborhoodA [
            if not member? ? ntemp [ set nToConsider lput ? nToConsider ]
          ]
          ;Como é
          ;nToConsider [3 13 15 16]
          ;Como deve ficar
          ;neighborhood0 [3 10 13 15 16 17 19]
          ;neighborhood3 [0 10 17 19] (faltou 13 15 16)
          ;neighborhood13 [0 10 15 17] (faltou 16)
          ;neighborhood16 [0 2 6 7 9 10 12 14] (foi tudo)
          ;nToConsider [3 13 16]
        ]
      ]
      [
        set nToConsider neighborhood
      ]

      let listaC []
      foreach nToConsider [
        ask ? [
          ;set listaC lput (sort-by < (lput meWho current-coalition)) listaC
          set listaC lput current-coalition listaC
        ]
      ]
      set listaC remove-duplicates listaC
      ;show listaC

      let remover []
      let vizinhos []
      foreach neighborhood [
        ask ? [
          set vizinhos lput (who + 1) vizinhos
        ]
      ]
      ;show vizinhos
      foreach listaC [
        let feasible? true
        foreach ? [
          if not member? ? vizinhos [
            set feasible? false
          ]
        ]
        if not feasible? [
          set remover lput ? remover
        ]
      ]
      foreach remover [
        set listaC remove ? listaC
      ]
      ;show listaC

      ifelse not empty? listaC [
        ;busca o valor de cada coalizão
        foreach listaC [
          set ? (sort-by < (lput meWho ?))
          let v getCoalitionValue ?
          if is-turtle? (turtle ((first ?) - 1))[
            ask (turtle ((first ?) - 1)) [
              if v <= coalition-value [
                set v -100;
              ]
            ]
          ]
          if v != -100 [
            set coalitions lput (list ? v) coalitions
          ]
        ]

        ;ordena as coalizões pelo valor
        set coalitions (sort-by [ (last ?1) > (last ?2) ] coalitions)
        ;show coalitions

        ;inicia o processo de convidar os vizinhos
        ifelse not empty? coalitions [
          invite-neighbors
        ]
        [
          set n-last-tries n-last-tries + 1
        ]

      ]
      [
        set n-last-tries n-last-tries + 1
      ]

      ifelse n-last-tries > 3[;length last-tries = 4 [
        set in-loop? true
        set n-last-tries 0
      ]
      [
        ;set in-loop? false
      ]

      ;if not empty? choosen-coalition [
        set last-tries lput choosen-coalition last-tries
      ;]

      ifelse length last-tries = 4 [
        set last-tries remove-item 0 last-tries
        ifelse length (remove-duplicates last-tries) = 1
        [ set in-loop? true ]
        [ set in-loop? false ]
      ]
      [
        set in-loop? false
      ]

;      ;meB - Para cada vizinho do meA
;      foreach reverse nToConsider [
;
;        let meB ?
;        let listaCoalizoesParAB (list (list meA meB))
;
;        ask meB [
;          ;meC - Para cada vizinho de meB
;          foreach reverse neighborhood [
;
;            let meC ?
;
;            if meC > meB and member? meC neighborhoodA [
;
;              let neighC []
;              ask meC [set neighC neighborhood]
;
;              let toAdd []
;              let toRemove[]
;
;              ;Tenta adicionar meC a cada uma das coalizões de listaCoalizoesParAB
;              foreach listaCoalizoesParAB [
;
;                let cAB ?
;                let conflitantes []
;
;                ;Encontra os elementos de cAB que não são vizinhos de meC
;                foreach cAB [
;                  if not member? ? neighC [
;                    set conflitantes lput ? conflitantes
;                  ]
;                ]
;
;                ;Se não tem conflitos, simplesmente adiciona meC a cAB
;                ;Se houver conflitos, cria uma coalizão nova sem os conflitantes, porém com meC
;                ifelse empty? conflitantes [
;                  set toRemove lput cAB toRemove
;                  set cAB lput meC cAB
;                  set toAdd lput cAB toAdd
;                ]
;                [
;                  let cn []
;                  foreach cAB [
;                    if not member? ? conflitantes [
;                      set cn lput ? cn
;                    ]
;                  ]
;                  set cn lput meC cn
;                  set toAdd lput cn toAdd
;                ]
;
;              ]
;
;              ;Adiciona as coalizões novas (que resolveram conflitos)
;              foreach toAdd [
;                set listaCoalizoesParAB lput (sort-by < ?) listaCoalizoesParAB
;              ]
;
;              foreach toRemove [
;                set listaCoalizoesParAB remove ? listaCoalizoesParAB
;              ]
;
;            ]
;
;          ]
;
;        ]
;
;        set matrizCoalizoesParesAB lput listaCoalizoesParAB matrizCoalizoesParesAB
;
;      ]
;
;      ;busca o valor de cada coalizão
;      ;show matrizCoalizoesParesAB
;      foreach matrizCoalizoesParesAB [
;        foreach ? [
;          let c coalitionName2coalitionNumber ?
;          set c (sort-by [ (?1) < (?2) ] c)
;          set coalitions lput (list c (getCoalitionValue c)) coalitions
;        ]
;      ]
;      ;ordena as coalizões pelo valor
;      ;show coalitions
;      set coalitions (sort-by [ (last ?1) > (last ?2) ] coalitions)
;
;      ;inicia o processo de convidar os vizinhos
;      if not empty? coalitions [
;        invite-neighbors
;      ]
    ]
  ]

end

to invite-neighbors

  set choosen-coalition first (first coalitions)
  let vC last (first coalitions)
  ;set in-loop? false

  ;envia mensagem para o lider pedindo para entrar na coalizão
  let leader (first choosen-coalition) - 1
  if leader = who [ set leader (item 1 choosen-coalition) - 1 ]
  let msg (list 1 who choosen-coalition vC);[tipo sender coalition coalition-value]
                                           ;foreach choosen-coalition[
                                           ;if (? - 1) != who [
  if is-turtle? (turtle leader) [
    ask turtle leader [
      set inbox lput msg inbox
    ]
  ]
  ;armazena o convite na lista de convites enviados
  ;set invitations-sent lput msg invitations-sent
  ;]
  ;]
  set waiting-for-replies? true

  show-monitoring who (word "[1]Escolheu " choosen-coalition " = " (getCoalitionValue choosen-coalition))


  ;atualiza a lista de últimas tentativas
  ;set last-tries lput choosen-coalition last-tries

;  ifelse length last-tries = 4 [
;    set last-tries remove-item 0 last-tries
;    ifelse length (remove-duplicates last-tries) = 1
;      [ set in-loop? true ]
;      [ set in-loop? false ]
;  ]
;  [
;    set in-loop? false
;  ]
;  ifelse not empty? choosen-coalition [
;    let msg (list 1 meA C vC);[tipo sender coalition coalition-value]
;    foreach C [
;      if (? - 1) != meA [
;        if is-turtle? (turtle (? - 1)) [
;          ask turtle (? - 1) [
;            set inbox lput msg inbox
;          ]
;        ]
;        ;armazena o convite na lista de convites enviados
;        ;set invitations-sent lput msg invitations-sent
;      ]
;    ]
;    set waiting-for-replies? true
;
;  ]
;  [ set in-loop? false ]
;
;  ;atualiza a lista de últimas tentativas
;    set last-tries lput choosen-coalition last-tries
;
;    ifelse length last-tries = 4 [
;      set last-tries remove-item 0 last-tries
;      ifelse length (remove-duplicates last-tries) = 1
;        [ set in-loop? true ]
;        [ set in-loop? false ]
;    ]
;    [
;      set in-loop? false
;    ]

end

to send-messages
  ask turtle 1 [
    ;let msg (list who coalition-size)
    ;ask my-links with [ color = gray ] [
    ;  ask other-end [
    ;    set inbox lput msg inbox
    ;  ]
    ;]
  ]
end

to-report coalitionName2coalitionNumber [ coalition ]
  let c []
  foreach coalition [
    ask ? [ set c lput (who + 1) c ]
  ]
  report c
end

to verify-neighbors_old
  ask turtle 1 [
    ;se houve alguma alteração e não há coalizões na lista de coalizões possíveis
    if changed? and empty? coalitions [
      let me turtle who
      let neighborhoodA lput me neighborhood
      foreach neighborhood [
        let coalition []
        ask ? [
          set coalition lput turtle who coalition
          foreach neighborhood [
            if member? ? neighborhoodA [
              set coalition lput ? coalition
            ]
          ]
        ]
        ;ordena a coalizão
        set coalition sort coalition
        ;adiciona à lista de coalizões possíveis
        if not empty? coalition [
          set coalitions lput coalition coalitions
        ]
      ]
      ;remove as coalizões inválidas
      ;remove-invalid-coalitions
      ;calcula o valor das coalizões e o adiciona à lista (cada item era [coalizão] agora fica [valor,coalizão]
      let Cs []
      foreach coalitions [
        let v 0
        let s length ?
        foreach ? [
          ask ? [
            ;if coalition-size < s [ set v v + 1 ]
          ]
        ]
        set Cs lput (list v ? ) Cs
      ]
      ;ordena a lista de coalizões pelo valor (do maior ao menor)
      set coalitions sort-by [first ?1 > first ?2] Cs
    ]
    ;se já existe uma lista de coalizões possíveis
    if not empty? coalitions [
      invite-neighbors2
    ]
  ]
end

to remove-invalid-coalitions
  ;remove as coalizões duplicadas
  set coalitions remove-duplicates coalitions

  foreach coalitions [
    ;show ?
  ]

end

to invite-neighbors2
  let coalition first coalitions
  let s first coalition
  set coalition last coalition
  set coalitions remove-item 0 coalitions
  foreach coalition [
    ask ? [
      set color red
      create-links-with other turtles with [member? self coalition] [ set color blue ]
    ]
  ]
end

to clear-inbox
  ask turtles [
    set inbox []
  ]
end

;to-report getCoalitionValueByID [s id]
;  report item id (item s values-matrix)
;end
to-report getCoalitionValueByID [s id]
  report getCoalitionValue (findCoalition s id)
end
;to-report getCoalitionValue [coalition]
;  report item (findCoalitionReverse coalition) (item (length coalition) values-matrix)
;end
to-report getCoalitionValue [coalition]
  report distribution:V2G coalition p gamma delta epsilon constante
end

to-report getPascal [l c]
  report matrix:get pascal-triangle l c
end

to-report findCoalition [ s id ]
  let c []
  let x 0
  let inc 0
  let l s
  while [l > 0] [
    ;show l
    set x 0
    while [(getPascal (s - inc - 1) x) < id] [ set x x + 1 ]
    set x x + 1
    ;show x
    set c lput ((n-of-agents - (s - inc) + 1) - x + 1) c
    set inc inc + 1
    ifelse (x - 2)  >= 0 [
      set id id + ((getPascal (s - inc) (x - 2)) * -1)
    ]
    [
      set id 1
    ]
    set l l - 1
  ]

  report c
end

to-report findCoalitionReverse [ c ]
  let id 0
  let s length c
  foreach c [
    let x n-of-agents - s - ? + 2
    ifelse s = 1 [
      set id id + (getPascal (s - 1) (x - 1))
    ]
    [
      if x > 1 [
        set id id + (getPascal (s - 1) (x - 2))
      ]
    ]
    set s s - 1
  ]
  report id
end

to generatePascalTriangle
  let n n-of-agents
  ;inicializa com zeros
  set pascal-triangle matrix:from-column-list n-values n [n-values n [0]]
  ;número de linhas
  let n1 n-values n [?]
  foreach n1 [
    let l ?
    ;número de colunas para a linha l
    let n2 n-values (n - l) [?]
    foreach n2 [
      let c ?
      ifelse l = 0 [
        matrix:set pascal-triangle l c (c + 1)
      ]
      [
        ifelse c = 0 [
          matrix:set pascal-triangle l c (1)
        ]
        [
          matrix:set pascal-triangle l c ((matrix:get pascal-triangle (l - 1) c) + (matrix:get pascal-triangle l (c - 1)))
        ]
      ]
    ]
  ]
  ;print matrix:pretty-print-text pascal-triangle
end


to teste-paper
  ;é preciso ajustar a view para 4x3, 30 pixels,
  ;e definir na procedure load-scenario "circle 3"
  ;e ajustar o shape circle 2 para deixar a borda fixa
  ask patches [set pcolor white]
  ask links [set color black]
  ask turtles [set color white]
end

to set-default-dir
  set-current-directory "//home//gabriel//Desktop//Submissões//SASO"
end

to teste
  let rep repetitions
  set repetitions 1
  show "n;Cenário;Tempo;V(CS)"
  set-current-directory "saved-scenarios"
  ;n={10,...,20} (11 agentes)
  foreach n-values 11 [? + 10] [
    let dir (word ? "agentes")
    set-current-directory dir
    ;30 cenários
    foreach n-values 30 [? + 1] [
      ;carrega o cenário
      let filename (word ?)
      if ? < 10 [set filename (word "0" filename)]
      file-open filename
      load-scenario

      ;roda o experimento
      show (word n-of-agents ";" ? ";" go-n-times-exp ";" processa-string (word CS-atual))

      set-current-directory dir
    ]
    set-current-directory ".."
    show ""
  ]
  set-current-directory ".."
  set repetitions rep
end

to teste2
  show "n;Cenário;Tempo;V(CS)"
  set-current-directory "saved-scenarios//20agentes"
  let dir (word "20agentes")
  let rep repetitions
  set repetitions 1
  ;30 cenários
  foreach n-values 30 [? + 1] [
    ;carrega o cenário
    let filename (word ?)
    if ? < 10 [set filename (word "0" filename)]
    file-open filename
    load-scenario

    ;roda o experimento
    show (word n-of-agents ";" ? ";" go-n-times-exp)

    ;salva a imagem, se desejado
    export-view (word "teste2//" n-of-agents"-scenario" filename "-view")
    export-all-plots (word "teste2//" n-of-agents"-scenario" filename "-plots")
    export-plot "V(CS)"(word "teste//" n-of-agents"-scenario" filename "-plots")

    set-current-directory dir

  ]
  export-output (word "teste2//" n-of-agents"-output.txt")
  set repetitions rep
  set-current-directory ".."
end

to kill-agent
  if one-of turtles with [in-coalition? = true] != nobody [
    ask one-of turtles with [in-coalition? = true] [
      ;se já faz parte de uma coalizão, avisa o coalition-leader que está saindo
      ifelse coalition-leader != who [
        let msg (list 4 who);[tipo remetente]
        if is-turtle? (turtle coalition-leader) [
          ask turtle coalition-leader [
            set inbox lput msg inbox
          ]
        ]
      ]
      [
        let me who
        foreach current-coalition [
          if ? != (me + 1) [
            if is-turtle? (? - 1) [
              ask turtle (? - 1) [
                set current-coalition (list (who + 1))
                set coalition-value getCoalitionValue current-coalition
                set coalition-leader who
                set coalition-color (item who colors)
                set in-coalition? false
                set time-in-coalition lput (ticks - last-join-unjoin) time-in-coalition
                set last-join-unjoin ticks
                set color (item coalition-leader colors)
              ]
            ]
          ]
        ]
      ]
      let me self
      foreach neighborhood [
        ask ? [
          set neighborhood remove me neighborhood
        ]
      ]
      set n-of-agents n-of-agents - 1
      set-agents-stat-info who 1 ticks
      die
    ]
  ]
end

to-report greatest [v1 v2]
  ifelse v1 > v2
    [ report v1 ]
    [ report v2 ]
end

to-report find-coalitions [ A B remaining ]
  let coalition (list A B)
  let Cs (list coalition)
  if empty? remaining [ report Cs ] ;rever

  ;let element first remaining
  ;set remaining remove 0 remaining
  foreach remaining [
    let current ?
    let remnant remove current remaining
    let C lput current coalition

    ;verifica se current é compativel com demais do remnant
    foreach remnant [
      let element ?
      let remnant2 remove element remnant

      foreach C [
        let yes? false
        ask ? [ if member? element neighborhood [ set yes? true ] ]
        ifelse yes?
        [
          set C lput ? coalition
        ]
        [
          show remove current C
          show element
          show remnant2
          foreach find-coalitions remove current C element remnant2 [
            set Cs lput ? Cs
          ]
        ]
      ]
      set Cs lput C Cs
    ]

    set C lput current C
    set Cs lput C Cs
    ;ask ? [
      ;ifelse member? element neighborhood
      ;  [  ]
    ;]
  ]
  show Cs

  report 0
end


to-report fat [v]
  ifelse v <= 1
    [ report 1 ]
    [ report v * fat( v - 1 ) ]
end

to update-coalition-structure
  let elementos n-values 150 [(list )]
  ask turtles [
    let lista item coalition-leader elementos
    set lista lput (who + 1) lista
    set elementos replace-item coalition-leader elementos lista
  ]
  let CS []
  let prevVCS VCS
  set VCS 0
  foreach elementos [
    if length ? > 0 [
      set CS lput (sort ?) CS
      set VCS VCS + getCoalitionValue (sort ?)
    ]
  ]

  set CS sort-by [length ?1 < length ?2 or (length ?1 = length ?2 and (first ?1) < (first ?2))] CS
  set CS-atual CS

  if not is-list? last-CSs [ set last-CSs [] ]
  set last-CSs lput CS-atual last-CSs
  if length last-CSs >= 10 [
    set last-CSs remove-item 0 last-CSs
    ifelse length (remove-duplicates last-CSs) = 1
      [ set is-stable? true ]
      [ set is-stable? false ]

  ]

  if show-CS and (VCS != prevVCS or ticks = 0) [

    let feasible? true
    foreach CS-atual [ if not is-feasible? ? [set feasible? false]]
    ifelse feasible?
      [show (word "CS = " CS ", V(CS) = " VCS " (feasible)")]
      [show (word "CS = " CS ", V(CS) = " VCS " (NOT feasible)")]


  ]
end

to generate-constraints-list
  let const n-values n-of-agents [list (? + 1) n-values n-of-agents [? + 1]]
  foreach const [
    let n first ?
    let lista last ?
    let toRemove []
    foreach lista [
      ifelse n != ? [
        ask turtle (n - 1) [
          if member? (turtle (? - 1)) neighborhood [
            set toRemove lput ? toRemove
          ]
        ]
      ]
      [
         set toRemove lput ? toRemove
      ]
    ]
    foreach toRemove [
      set lista remove ? lista
    ]
    set const replace-item (n - 1) const (list n lista)
  ]
;  foreach const [
;    let str "restricoes.add(novoArrayList("
;    let prim true
;    foreach (last ?) [
;      ifelse prim = true [
;        set str (word str ?)
;        set prim false
;      ]
;      [
;        set str (word str ", " ?)
;      ]
;    ]
;    show (word str "));")
;  ]
  let string (word "else if (t==" aux ") { " )
  foreach const [
    let str (word "criaD(" (first ?))
    foreach (last ?) [
      set str (word str ", " ?)
    ]
    ;print (word str ");")
    set string (word string str "); ")
  ]
  show (word string "}")
  ;show const
end

to-report getCoalitionListSize [ n s ]
  report getPascal (s - 1) (n - s)
end

to-report genValueDistUniform [ s ]
  report (greatest (random-float s) 0)
end

to-report genValueDistNormal [ s ]
  report (greatest (random-normal s 1) 0)
end

to-report genValueDistCardinality [ s ]
  ifelse s >= 2 and s <= n-of-agents / 3
    [ report s ]
    [ report 0 ]
end

to do-plots
  update-coalition-structure
  set-current-plot "V(CS)"
  set-current-plot-pen "value";distribution
  if ticks > 10 [ set-plot-x-range 0 (ticks + 1) ]
  ;set-plot-y-range 0 (max (list ((VCS * 1.1)) 0.0001))
  if ticks = 0 [ plot 0 ]
  plot VCS

  ;----------------------------------------------------------

  count-messages
  set-current-plot "messages"
  set-current-plot-pen "default"
  if ticks > 10 [ set-plot-x-range 0 (ticks + 1) ]
  if ticks = 0 [ plot 0 ]
  plot n-of-messages

  ;----------------------------------------------------------

  let ttj []
  let tic []
;  ask turtles with [last-join-unjoin != ticks] [
;    ifelse in-coalition? [
;      ;show who
;      set tic lput (ticks - last-join-unjoin) tic
;    ]
;    [
;      set ttj lput (ticks - last-join-unjoin) ttj
;    ]
;  ]
  ask turtles [
    ifelse in-coalition?
      [ set tic lput (ticks - last-join-unjoin) tic ]
      [ if not in-loop? [ set ttj lput (ticks - last-join-unjoin) ttj ] ]
  ]

  if ticks = 0 or empty? time-to-join [
    set time-to-join [0]
  ]
  set-current-plot "time to join"
  set-current-plot-pen "default"
  if ticks > 10 [ set-plot-x-range 0 (ticks + 1) ]
  if ticks = 0 [ plot 0 ]
  ;plot mean (sentence time-to-join ttj)
  ifelse not empty? ttj
   [
     plot mean ttj;(sentence time-to-join ttj)
     set avg-time-to-join avg-time-to-join + mean ttj;(sentence time-to-join ttj)
   ]
   [ plot 0 ]

  if ticks = 0 or empty? time-in-coalition [
    set time-in-coalition [0]
  ]
  set-current-plot "time in coalition"
  set-current-plot-pen "default"
  if ticks > 10 [ set-plot-x-range 0 (ticks + 1) ]
  if ticks = 0 [ plot 0 ]
  ;plot mean time-in-coalition
  ifelse not empty? tic
   [
     plot mean tic;(sentence time-in-coalition tic)
     set avg-time-in-coalition avg-time-in-coalition + mean tic;(sentence time-in-coalition tic)
   ]
   [ plot 0 ]

  ;----------------------------------------------------------

  set-current-plot "average instant payoff"
  set-current-plot-pen "default"
  if ticks > 10 [ set-plot-x-range 0 (ticks + 1) ]
  if ticks = 0 [ plot 0 ]
  plot avg-payoff

  ;----------------------------------------------------------

  let agents-out 0
  let ncoa 0
  let scoa 0
  if is-list? CS-atual [
    foreach CS-atual [
      ifelse length ? <= 1
        [ set agents-out agents-out + 1 ]
        [ set ncoa ncoa + 1
          set scoa scoa + (length ?) ]
    ]
  ]
  set agents-out agents-out * 100 / n-of-agents
  set avg-agents-out avg-agents-out + agents-out

  set-current-plot "% of agents in/out coalition"
  set-current-plot-pen "in coalition"
  if ticks = 0 [ plot 0 ]
  plot 100 - agents-out
  set-current-plot-pen "out coalition"
  if ticks = 0 [ plot 0 ]
  plot agents-out
  if ticks > 10 [ set-plot-x-range 0 (ticks + 1) ]

  ;----------------------------------------------------------

  set-current-plot "number of coalitions"
  set-current-plot-pen "default"
  if ticks > 10 [ set-plot-x-range 0 (ticks + 1) ]
  if ticks = 0 [ plot 0 ]
  plot ncoa

  ;----------------------------------------------------------

  set-current-plot "avg coalition size"
  set-current-plot-pen "default"
  if ticks > 10 [ set-plot-x-range 0 (ticks + 1) ]
  if ticks = 0 [ plot 0 ]
  ifelse ncoa > 0
    [ plot scoa / ncoa ]
    [ plot 0 ]

end

to save-distribution
  let monthsPt ["Jan" "Fev" "Mar" "Abr" "Mai" "Jun" "Jul" "Ago" "Set" "Out" "Nov" "Dez"]
  let monthsEn ["Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"]
  let monthsNum ["01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12"]
  let date date-and-time
  let year substring date 23 27
  let month substring date 19 22
  set month item (position month monthsPt)  monthsNum
  let day substring date 16 18
  let hour substring date 0 2
  let ampm substring date 13 15
  if ampm = "PM" [ set hour (read-from-string hour) + 12 ]
  let minutes substring date 3 5
  let seconds substring date 6 8
  let fileName (word distribution n-of-agents "agents_" year month day hour minutes seconds ".txt")

  set-current-directory "generated-distributions"
  file-open fileName
  foreach n-values n-of-agents [? + 1] [
    let s ?
    foreach n-values (getCoalitionListSize n-of-agents s) [? + 1] [
      file-print (word "[" s " " ? " " (getCoalitionValueByID s ?) "]")
    ]
  ]
  file-close
  set-current-directory ".."
end

to reset-graph
  ask turtles [
    set inbox []
    set coalitions []
    set coalition-color (item who colors)
    set coalition-leader who
    set current-coalition (list (who + 1))
    set invitations-received []
    set final-replies []
    set invitation-selected []
    set invitations-replies []
    set in-coalition? false
    set last-join-unjoin 0
    set in-loop? false
    set last-tries []
    set n-last-tries 0
    set waiting-for-replies? false
    set has-accepted? false
    set waiting-final? false
    set choosen-coalition []
    set iterations-to-new-join 0
    set accumulated-value 0
    set active-since 0
  ]

  set is-stable? false
  set VCS 0

  ;ifelse not user-yes-or-no? "Keep the current distribution?"
  ;  [ setup-values ]
  ;  [ ask turtles [ set coalition-value (getCoalitionValueByID 1 (who + 1)) ] ]
  ask turtles [ set coalition-value (getCoalitionValue current-coalition)];ByID 1 (who + 1)) ]

  set color-option 1
  change-colors

  clear-all-plots

  reset-ticks

end

to choose-other-distribution
  set other-distribution user-file
  file-open other-distribution
  print file-read-line
  file-close
end

to create-new-agent
  if distribution != "fileV2G1" and distribution != "distributionExt" [
    user-message "Creating new agents is allowed only for distributions 'fileV2G1' and 'distributionExt'."
    stop
  ]
  if n-of-agents >= 100 [
    user-message "The maximum number of agents was reached."
    stop
  ]
  ask one-of patches with [ not any? turtles-here] [
    ;cria o novo agente
    sprout 1 [
      ;-----------------------
      set color blue
      set changed? true
      set neighborhood []
      set neighborhoodG []
      set inbox []
      set coalitions []
      set coalition-color (item who colors)
      set coalition-leader who
      set current-coalition (list (who + 1))
      ;set invitations-sent []
      set invitations-received []
      set final-replies []
      set invitation-selected []
      set invitations-replies []
      set in-coalition? false
      set last-join-unjoin 0
      set in-loop? false
      set last-tries []
      set n-last-tries 0
      set waiting-for-replies? false
      set has-accepted? false
      set waiting-final? false
      set choosen-coalition []
      set iterations-to-new-join 0
      set accumulated-value 0
      set active-since ticks
      ;adiciona a cada agente um label centralizado com seu número
      ifelse who > 8
        [ set label word (who + 1) "  "]
        [ set label word (who + 1) "   "]
      ;-----------------------
      ;cria os links
      let meA self
      let n []
      let nG []
      let tx xcor
      let ty ycor
      ;cria links entre agentes que podem formar coalizão
      create-links-with other turtles with [sqrt (((xcor - tx) ^ 2) + ((ycor - ty) ^ 2)) < alpha] [ set color gray ]
      ;monta lista de vizinhos
      ask my-links with [ color = gray ] [
        ifelse meA < other-end
        [ set nG lput other-end nG ]
        [ ask other-end [ set neighborhoodG sort-by < (lput meA neighborhoodG) ] ]
        set n lput other-end n
        ask other-end [ set neighborhood sort-by < (lput meA neighborhood) ]
      ]
      set neighborhood sort-by < n
      set neighborhoodG sort-by < nG
    ]
    ;-----------------------
    ;setup-values
    ;alterar o mecanismo de cálculo dos valores. ao invés de armazenar tudo na memória, armazenar em arquivos.
    ;o único problema a resolver é que não dá para escolher a linha do arquivo que será lida, pois ele só pode ser lido sequencialmente.
    ;a melhor alternativa para isto é criar uma extensão java para usar aqui no netlogo, barbada! (https://github.com/NetLogo/NetLogo/wiki/Extensions-API)
    ;outra alternativa (que é muito ruim) é criar um arquivo para cada coalizão. o arquivo conteria o valor da coalizão que representa,
    ;o nome do arquivo seria o id da coalizão e cada arquivo ficaria no diretório correspondente ao tamanho de sua coalizão.
    ;-----------------------
    ;incrementa o número de agentes
    set n-of-agents n-of-agents + 1
    new-agents-stat-info
  ]
  ;atualiza as cores
  change-colors
  change-colors
end

to-report is-there-working-agents?
  if is-stable? [ report false ]
  let w 0
  ask turtles with [ not in-coalition? and not in-loop? and not empty? neighborhood ] [ set w w + 1 ]
  ifelse w > 0
    [ report true ]
    [ report false ]
end

to save-scenario
  set-current-directory (word "saved-scenarios//" n-of-agents "agentes")
  file-open user-new-file
  foreach n-values n-of-agents [?] [
    ask turtle ? [
      file-print (list xcor ycor)
    ]
  ]
  file-close
  set-current-directory "..//.."
end

to open-scenario
  set-current-directory "saved-scenarios"
  file-open user-file
  load-scenario
end

to load-scenario
  clear-all
  reset-ticks

  set cor1 rgb 230 230 230
  set cor2 rgb 250 250 250

  set-colors

  set color-option 1

  set-default-shape turtles "circle"

  while [ not file-at-end? ] [
      let str read-from-string file-read-line
      let x item 0 str
      let y item 1 str
      ask patch x y [
        sprout 1 [
          set color blue
          set changed? true
          set neighborhood []
          set neighborhoodG []
          set inbox []
          set coalitions []
          set coalition-color (item who colors)
          set coalition-leader who
          set current-coalition (list (who + 1))
          ;set invitations-sent []
          set invitations-received []
          set final-replies []
          set invitation-selected []
          set invitations-replies []
          set in-coalition? false
          set last-join-unjoin 0
          set in-loop? false
          set last-tries []
          set n-last-tries 0
          set waiting-for-replies? false
          set has-accepted? false
          set waiting-final? false
          set choosen-coalition []
          set iterations-to-new-join 0
          set accumulated-value 0
          set active-since 0
          ;adiciona a cada agente um label centralizado com seu número
          ifelse who > 8
          [ set label word (who + 1) "  "]
          [ set label word (who + 1) "   "]
          new-agents-stat-info
        ]
      ]
  ]
  file-close
  set-current-directory ".."

  setup-patches
  setup-links
  change-colors
  setup-values

  set is-stable? false

  set n-of-agents count turtles
end

to run-experiments-closed-world
  show "n;Cenário;Tempo;V(CS)"
  set-current-directory "saved-scenarios"
  ;n={10,...,20} (11 agentes)
  foreach n-values 11 [? + 10] [
    let dir (word ? "agentes")
    set-current-directory dir
    ;30 cenários
    foreach n-values 30 [? + 1] [
      ;carrega o cenário
      let filename (word ?)
      if ? < 10 [set filename (word "0" filename)]
      file-open filename
      load-scenario

      ;roda o experimento
      show (word n-of-agents ";" ? ";" go-n-times-exp)

      ;salva a imagem, se desejado
      if export-views? [export-view (word "img-exp//" n-of-agents"-scenario" filename)]

      set-current-directory dir
    ]
    set-current-directory ".."
    show ""
  ]
  set-current-directory ".."
end

to run-experiments-open-world
  set-current-directory "run"

  ;number of runs
  let n 30

  foreach n-values n [? + 1] [
    print (word "Running replication " ? " of " n)
    ;randomly create a scenario
    setup

    ;run all steps
    while [ticks < max-ticks] [ go-forever ]

    ;export plots of interest
    export-plot "V(CS)" (word "VCS-run" ? ".csv")

    ;export world
    export-world (word "world-run" ? ".csv")
  ]

  set-current-directory ".."
end

to run-experiments-open-world-old
  show "n;Tempo;V(CS)"
  ;set-current-directory "saved-scenarios//open"

  ;carrega o cenário
  file-open user-file;"40agentes"
  load-scenario

  ;roda o experimento
  show (word n-of-agents ";" go-n-times-exp)

  ;salva a imagem, se desejado
  ;if export-views? [export-view (word "img-exp//" n-of-agents"-scenario" filename)]

  set-current-directory "..//.."
end

to-report replace-str [str old new]
  let dec length str
  while [is-number? position old str and dec > 0] [
    set str replace-item (position old str) str new
    set dec dec - 1
    if dec <= 0 [ show (word "Loop infinito! (" str ", " old ", " new")") ]
  ]
  report str
end

to-report processa-string [str]
  let subst (list ["[" "{"] ["]" "}"] ["." ","] [" " ","])
  foreach subst [
    set str replace-str str item 0 ? item 1 ?
  ]
  report str
end

;to calculate-instant-payoff
;  set avg-payoff 0
;  let cnt 0
;  ask turtles with [in-coalition?] [
;    set accumulated-value accumulated-value + ((coalition-value / 60 / (length current-coalition)) * 3.3) ;considerando que a bateria de um EV tem 3.3kWh
;    if ticks - active-since > 0 [
;      set avg-payoff avg-payoff + (accumulated-value / (ticks - active-since))
;    ]
;    set-agents-stat-info who 5 accumulated-value
;    set cnt cnt + 1
;  ]
;  set avg-payoff avg-payoff / cnt
;end

to calculate-instant-payoff
  set avg-payoff 0
  let cnt 0
  ask turtles [
    ;let inst ((coalition-value / 60 / (length current-coalition)) * 3.3) ;considerando que a bateria de um EV tem 3.3kWh
    let inst (coalition-value * 3.3 / 60) ;considerando que a bateria de um EV tem 3.3kWh
    set accumulated-value accumulated-value + inst
    if in-coalition? [
      set avg-payoff avg-payoff + inst;(accumulated-value / ((get-agents-stat-info who 4) - (get-agents-stat-info who 3)))
      set cnt cnt + 1
    ]
    set-agents-stat-info who 5 accumulated-value
  ]
  if cnt > 0
    [ set avg-payoff avg-payoff / cnt ]
end

to calculate-final-payoff
  let payoff 0
  ask turtles [
    set payoff payoff + accumulated-value
  ]
  set payoff payoff / n-of-agents
  show payoff * 3.3 ;considerando que a bateria de um EV tem 3.3kWh
end

to-report get-agents-stat-info [ag info]
  report item info (item ag agents-info)
end

;0 = turtle (who)
;1 = entrada (ticks)
;2 = saída (ticks)
;3 = tempo em coalizão (incrementa)
;4 = tempo sozinho (incrementa)
;5 = instantant payoff
to set-agents-stat-info [ag info new]
  ifelse member? info [3 4] ;itens que são incrementados, apenas
    [ set agents-info replace-item ag agents-info (replace-item info (item ag agents-info) ((item info (item ag agents-info)) + 1)) ]
    [ set agents-info replace-item ag agents-info (replace-item info (item ag agents-info) new) ]
  set agents-info replace-item ag agents-info (replace-item 2 (item ag agents-info) (ticks + 1))
end

to new-agents-stat-info
  if not is-list? agents-info
    [ set agents-info [] ]
  set agents-info lput (list (length agents-info) ticks ticks 0 0 0) agents-info
end

to-report union [setA setB]
  let newSet setA
  ifelse not is-list? setB [
    set newSet lput setB newSet
  ]
  [
    foreach setB [
      set newSet lput ? newSet
    ]
  ]
  report newSet
end

to-report minus [setA setB]
  let newSet setA
  ifelse not is-list? setB [
    set newSet remove setB newSet
  ]
  [
    foreach setB [
      set newSet remove ? newSet
    ]
  ]
  report newSet
end

to-report get-best-coalition [Cs]
  let best []
  let bestV -1
  foreach Cs [
    ;show (word ? " = " (getCoalitionValue ?))
    if getCoalitionValue ? > bestV [
      set best ?
      set bestV getCoalitionValue ?
    ]
  ]
  report best
end

to-report is-feasible? [coalition]
  let answer true
  foreach n-values ((length coalition) - 1) [?] [
    let a1 item ? coalition
    let x ?
    if is-turtle? turtle (a1 - 1) [
      ask turtle (a1 - 1) [
        foreach n-values ((length coalition) - x - 1) [? + x + 1] [
          let a2 item ? coalition
          if not member? (turtle (a2 - 1)) neighborhood [
            set answer false
          ]
        ]
      ]
    ]
  ]
  report answer
end

to-report get-feasible-coalitions [ i N ]
  let FCi []
  ;let Ni []
  ;ask turtle (i - 1) [ set Ni sort-by > turtles2numbers neighborhood ]
  foreach reverse N [
    let n1 ?
    ;let Nn1 []
    ;ask turtle (n1 - 1) [ set Nn1 sort-by > turtles2numbers neighborhood ]

    set FCi lput (sort-by < (list i ?)) FCi

    foreach N [
      if ? > n1 [; and member? ? Ni [
        let n2 ?
        let Nn2 []
        ask turtle (n2 - 1) [ set Nn2 sort-by > turtles2numbers neighborhood ]

        let FCi-new []
        foreach FCi [
          let C ?
          ifelse empty? minus C Nn2 [
            set C sort-by < union C n2
            set FCi-new lput C FCi-new
          ]
          [
            let Cnew sort-by < union (minus C (minus C Nn2)) n2
            set FCi-new lput C FCi-new
            set FCi-new lput Cnew FCi-new
          ]
        ]
        set FCi sort-by [length ?1 > length ?2] remove-duplicates FCi-new

      ]
    ]
  ]
  report FCi
end

to-report get-feasible-coalitions_old [ i N ]
  let FCi []
  let Ni []
  ask turtle (i - 1) [ set Ni sort-by > turtles2numbers neighborhood ]
  foreach reverse N [
    let n1 ?
    let Nn1 []
    ask turtle (n1 - 1) [ set Nn1 sort-by > turtles2numbers neighborhood ]

    set FCi lput (list i ?) FCi

    foreach Nn1 [
      if ? > n1 and member? ? Ni [
        let n2 ?
        let Nn2 []
        ask turtle (n2 - 1) [ set Nn2 sort-by > turtles2numbers neighborhood ]

        let FCi-new []
        foreach FCi [
          let C ?
          ifelse empty? minus C Nn2 [
            set C sort-by < union C n2
            set FCi-new lput C FCi-new
          ]
          [
            let Cnew sort-by < union (minus C (minus C Nn2)) n2
            set FCi-new lput C FCi-new
            set FCi-new lput Cnew FCi-new
          ]
        ]
        set FCi sort-by [length ?1 > length ?2] remove-duplicates FCi-new

      ]
    ]
  ]
  report FCi
end

;recebe o who do turtle
;imprime o (número do turtle + 1) e a mensagem
to show-monitoring [ag str]
  if false [
    if member? ag [5 8 11] [
      show (word (ag + 1) ": " str)
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
286
10
596
341
7
7
20.0
1
10
1
1
1
0
0
0
1
-7
7
-7
7
0
0
1
ticks
30.0

BUTTON
12
10
86
43
NIL
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
93
10
157
44
Go
print (word \"------------------------------------\\n\" ticks \"\\n\")\nGo\n;let i (list 0 2 3 5)\n;let i n-values 10 [?]\n;foreach i [ask turtle ? [print (word ? \"\\n\" choosen-coalition \"\\n\" coalitions \"\\n\" inbox \"\\n\")]]
NIL
1
T
OBSERVER
NIL
G
NIL
NIL
1

INPUTBOX
12
160
173
220
alpha
7
1
0
Number

BUTTON
1279
63
1389
96
NIL
clear-inbox
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1284
103
1354
136
NIL
teste
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1283
145
1617
178
optimize-potential-coalition-generation
optimize-potential-coalition-generation
1
1
-1000

SLIDER
12
238
184
271
n-of-agents
n-of-agents
2
100
50
1
1
NIL
HORIZONTAL

CHOOSER
12
99
150
144
scenario
scenario
"random" "7-agents"
0

BUTTON
1272
21
1423
54
NIL
change-colors
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1289
267
1499
300
NIL
generate-constraints-list
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
12
289
185
334
distribution
distribution
"distributionExt" "cardinality" "normal" "uniform" "fileNormal" "fileNormal80" "fileV2G1" "other"
0

PLOT
603
150
1098
300
V(CS)
tick
value
0.0
10.0
0.0
0.01
true
false
"" ""
PENS
"fileNormal" 1.0 0 -13345367 true "" ""
"fileNormal80" 1.0 0 -15040220 true "" ""
"fileV2G1" 1.0 0 -2674135 true "" ""
"value" 1.0 0 -13791810 true "" ""

BUTTON
1286
230
1437
263
NIL
save-distribution
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1285
190
1402
223
show-CS
show-CS
1
1
-1000

BUTTON
1287
304
1404
337
NIL
reset-graph
NIL
1
T
OBSERVER
NIL
R
NIL
NIL
1

BUTTON
188
289
258
334
Open
choose-other-distribution
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
12
337
243
382
NIL
other-distribution
17
1
11

BUTTON
188
238
251
271
new
create-new-agent
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
770
10
931
70
gamma
1000
1
0
Number

INPUTBOX
936
10
1097
70
delta
50
1
0
Number

INPUTBOX
1102
10
1263
70
epsilon
0.9
1
0
Number

INPUTBOX
603
10
764
70
p
0.5
1
0
Number

INPUTBOX
603
81
764
141
constante
12345
1
0
Number

BUTTON
1285
351
1417
384
NIL
save-scenario
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1285
387
1420
420
NIL
open-scenario
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
163
49
273
109
repetitions
30
1
0
Number

BUTTON
12
49
156
82
NIL
go-n-times
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
770
82
931
142
p_e
0.005
1
0
Number

INPUTBOX
936
82
1097
142
p_l
0.005
1
0
Number

SWITCH
1286
427
1412
460
slow-ticks
slow-ticks
1
1
-1000

SLIDER
1246
472
1418
505
interval
interval
0
1
0.2
0.1
1
sec
HORIZONTAL

SWITCH
1102
150
1245
183
open-world?
open-world?
0
1
-1000

PLOT
603
306
1098
456
messages
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

INPUTBOX
1102
83
1263
143
max-ticks
1440
1
0
Number

PLOT
603
616
1098
766
n-of-agents
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" "if ticks > 10 [ set-plot-x-range 0 (ticks + 1) ]"
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

BUTTON
1307
512
1370
545
facil
foreach n-values 29 [? + 2] [\nsetup\nifelse ? < 10 [set aux (word \"0\" ?) ][set aux (word ?)]\ngo-forever\nsave-scenario\ngenerate-constraints-list\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
12
387
255
420
NIL
run-experiments-closed-world
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
259
387
411
420
export-views?
export-views?
1
1
-1000

PLOT
603
460
1098
610
time to join
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
101
460
597
610
time in coalition
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
101
616
597
766
average instant payoff
NIL
NIL
0.0
10.0
0.0
1.0E-5
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

BUTTON
1278
567
1458
600
NIL
calculate-final-payoff
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
163
10
273
43
Go-Forever
ifelse ticks < max-ticks and (open-world? or (not open-world? and is-there-working-agents?))\n  [ ;print (word \"------------------------------------\\n\" ticks \"\\n\")\n  go-forever ]\n  [ stop ]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
603
772
1098
922
% of agents in/out coalition
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"in coalition" 1.0 0 -13791810 true "" ""
"out coalition" 1.0 0 -2674135 true "" ""

MONITOR
1103
839
1264
884
avg-agents-in-coalition
100 - (avg-agents-out / ticks)
17
1
11

PLOT
101
772
597
922
number of coalitions
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
101
927
597
1077
avg coalition size
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

MONITOR
19
532
95
577
avg-time-in-coalition
avg-time-in-coalition / ticks
3
1
11

MONITOR
1104
529
1218
574
avg-time-to-join
avg-time-to-join / ticks
3
1
11

BUTTON
12
425
255
458
NIL
run-experiments-open-world
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1151
366
1284
399
set default dir
set-default-dir
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

circle 3
false
15
Circle -16777216 true false 0 0 300
Circle -1 true true 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
