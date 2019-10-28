extensions [matrix distribution]

globals [
  values-matrix
  pascal-triangle
  colors
  VCS
  CS-atual
  other-distribution
  n-of-messages
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

  ;MAGS
  departure-time
  forming-new?
]

to setup

  clear-all

  reset-ticks

  set-colors

  setup-turtles
  setup-patches
  setup-links

  change-colors
  setup-values

  set is-stable? false

end

to set-colors
  set colors []
  set colors n-values 140 [?]
  foreach n-values 13 [(? + 1) * 10] [
    set colors remove ? colors
  ]
  ;MAGS - increases the list 10 times
  let ctemp colors
  foreach n-values 10 [?] [
    foreach ctemp [
      set colors lput ? colors
    ]
  ]
  set colors shuffle colors
end

to change-colors
  ask turtles [
    set color (item coalition-leader colors)
    ifelse color mod 10 <= 3
      [ set label-color white ]
      [ set label-color black ]
  ]
end

to setup-values
  ;Gera o triângulo de Pascal
  generatePascalTriangle

  ;set pascal-triangle matrix:from-column-list n-values n-of-agents [n-values n-of-agents [0]]
  ;matrix:set pascal-triangle l c ((matrix:get pascal-triangle (l - 1) c) + (matrix:get pascal-triangle l (c - 1)))

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

      ;MAGS
      set departure-time gen-departure-time
      set forming-new? false
    ]
  ]
end

to setup-patches
  ask patches [
    ;patches em xadrez
    ifelse ((pxcor mod 2 = 0) and (pxcor mod 2 = 0 and pycor mod 2 = 0)) or ((pxcor mod 2 = 1) and (pxcor mod 2 != 0 and pycor mod 2 != 0))
     [ set pcolor [230 230 230] ]
     [ set pcolor [250 250 250] ]
  ]
end

to setup-links
  ask turtles [
    let n []
    let nG []

    ;MAGS
    ;let tx xcor
    ;let ty ycor
    let dt departure-time

    ;cria links entre agentes que podem formar coalizão
    ;create-links-with other turtles with [sqrt (((xcor - tx) ^ 2) + ((ycor - ty) ^ 2)) < alpha] [ set color gray ]
    ;MAGS
    create-links-with other turtles with [abs (dt - departure-time) <= alpha] [ set color gray ]

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

  ;MAGS
  ;mata agentes que atingiram se departure-time
  kill-departure

  if not any? turtles [ stop ]

  ;reset-timer

  ;lê mensagens recebidas
  read-messages

  ask turtles with [iterations-to-new-join > 0] [set iterations-to-new-join iterations-to-new-join - 1]

  process-final

  ;processa as respostas a convites
  process-replies

  ;#### sempre que tiver convites ele responde. se tiver uma resposta e a coalizão for formada, responde não a todos os convites com resposta 3=nao
  ;processa os convites recebidos
  process-invitations

  ;convida vizinhos
  verify-neighbors;optei por tentar verificar os vizinhos apenas se não tiver convites e se eu não estiver em uma coalizão

  ;MAGS
  ;process-reductions

  do-statistics

  ;atualiza os gráficos
  do-plots

  tick

  ;print timer

end

to process-reductions
  ask turtles with [in-coalition? and
                    coalition-leader = who and
                    not forming-new? and
                    not waiting-final?] [
    let newC check-reductions current-coalition
    let newV getCoalitionValue newC
    print (word "Current: " current-coalition " (" coalition-value "), best reduction: " newC " (" newV ")")
  ]
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
    if random-float 1 < p_e and n-of-agents < 127[
      create-new-agent
    ]

    if random-float 1 < p_l and n-of-agents > 2 and ticks > 3 [
      kill-random
    ]

    ;MAGS
    ;kill agents that achieved their departure time

   ]

   go

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
          show-monitoring who (word "new = " newCoalition)

          foreach newCoalition [

            if is-turtle? (turtle (? - 1)) [
              ask turtle (? - 1) [

                ;MAGS
                if forming-new? [
                  ;show "AQUI!!!!!!!!!!!!!!!!!!!****"
                  cancel-current-coalition
                  set forming-new? false
                ]

                ;define o líder
                set coalition-leader meA
                set current-coalition sort-by < newCoalition

                ;atualiza o valor da coalizão
                set coalition-value vC

                ;atualiza a cor da coalizão
                set coalition-color (item coalition-leader colors)
                set color coalition-color
                ifelse color mod 10 <= 3
                [ set label-color white ]
                [ set label-color black ]

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

              ;MAGS
              set forming-new? false
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

      set waiting-for-replies? false

      let accept? false
      let reject? false

      let rem item 0 (first invitations-replies)
      let C item 1 (first invitations-replies)
      let resp item 2 (first invitations-replies)

      ifelse not in-coalition? or
             (in-coalition? and forming-new?) ;MAGS
      [
        ifelse not empty? invitation-selected [

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
            ;let vC getCoalitionValue C
            ;let vCsel getCoalitionValue invitation-selected
            ;MAGS
            let vC getEnergyPriceOnCoalition C
            let vCsel getEnergyPriceOnCoalition invitation-selected

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

            ;MAGS
            set forming-new? false
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

        ;MAGS - cancel current coalition
        if forming-new? [
          cancel-current-coalition
        ]

      ]

      if reject? [
        show-monitoring who (word "[3]Cancelou " C)
        ;cancela o interesse
        let msg (list 5 who C 2);[tipo remetente coalition resposta]
        if is-turtle? (turtle rem) [
          ask turtle rem [
            set inbox lput msg inbox
          ]
        ]
      ]

    ]
    [

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
      if is-turtle? ag1 [
        ask ag1 [
          if not member? ag2 neighborhood [
            set neighbours? false;set vizinhos? false
          ]
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
        ;agente que recebeu o pedido está em uma coalizão (então ele é o líder)
        ifelse in-coalition? [
          ;apenas um pedido
          ifelse length invitations-received = 1 [
            set newCoalition sort-by < (union current-coalition (first (first invitations-received) + 1))

            if not usa-if? or (usa-if? and (getEnergyPriceOnCoalition newCoalition > getEnergyPriceOnCoalition current-coalition or abs (getEnergyPriceOnCoalition newCoalition - getEnergyPriceOnCoalition current-coalition) <= 0.00001)) [;MAGS - accept only if value is better (although requester ask for permission only if the coalition value is improved, sometimes the coalition value can improve BETWEEN and phase1 and phase2)
              if is-feasible? newCoalition [
                set accepted true
                set acceptDirect true
              ]
            ]
            ;show newCoalition
          ]
          [
            ;todos que pediram são vizinhos
            ifelse are-neighbours? lv [

              set newTurtles numbers2turtles minus lv (meA + 1)
              set newCoalition sort-by < union current-coalition minus lv (meA + 1)

              ;MAGS
              let newCred check-reductions newCoalition
              set newTurtles (minus newTurtles (minus newCoalition newCred))
              set newCoalition newCred

              if not usa-if? or (usa-if? and (getEnergyPriceOnCoalition newCoalition > getEnergyPriceOnCoalition current-coalition or abs (getEnergyPriceOnCoalition newCoalition - getEnergyPriceOnCoalition current-coalition) <= 0.00001)) [;MAGS - accept only if value is better (although requester ask for permission only if the coalition value is improved, sometimes the coalition value can improve BETWEEN and phase1 and phase2)
                if is-feasible? newCoalition [
                  set accepted true
                  set acceptDirect true
                ]
              ]
              ;show newCoalition
            ]
            ;NEM todos que pediram são vizinhos
            [
              ;MAGS
              ;let bestFeasible minus (get-best-coalition get-feasible-coalitions (meA + 1) lv) (meA + 1)
              let bestFeasible minus (get-best-coalition (get-reductions (get-feasible-coalitions (meA + 1) lv))) (meA + 1)

              set newTurtles numbers2turtles bestFeasible;minus bestFeasible meA
              set newCoalition sort-by < union current-coalition bestFeasible

              if not usa-if? or (usa-if? and (getEnergyPriceOnCoalition newCoalition > getEnergyPriceOnCoalition current-coalition or abs (getEnergyPriceOnCoalition newCoalition - getEnergyPriceOnCoalition current-coalition) <= 0.00001)) [;MAGS - accept only if value is better (although requester ask for permission only if the coalition value is improved, sometimes the coalition value can improve BETWEEN and phase1 and phase2)
                if is-feasible? newCoalition [
                  set accepted true
                  set acceptDirect true
                ]
              ]
            ]
          ]
        ]
        ;agente que recebeu o pedido NÃO está em uma coalizão
        [
          if length choosen-coalition < 3 [;MAGS (I guess this code is to avoid processing requests when other phases are being processed)
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

                ;MAGS
                let newCred check-reductions newCoalition
                set newTurtles numbers2turtles (minus (minus lv (meA + 1)) (minus newCoalition newCred))
                set newCoalition newCred

                if is-feasible? newCoalition [
                  set accepted true
                ]
              ]
              ;NEM todos que pediram são vizinhos
              [

                ;MAGS
                ;let bestFeasible minus (get-best-coalition get-feasible-coalitions (meA + 1) lv) (meA + 1)
                let bestFeasible minus (get-best-coalition (get-reductions (get-feasible-coalitions (meA + 1) lv))) (meA + 1)

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

      ;aceitou pedidos (avisos de sim e não)
      ifelse accepted [

        ;em alguns casos, aceita direto sem precisar trocar mensagens
        ifelse acceptDirect [
          ;show "ACEITO DIRETO!"

          let vC getCoalitionValue newCoalition
          foreach newCoalition [
            if is-turtle? (turtle (? - 1)) [
              ask turtle (? - 1) [

                ;MAGS
                if forming-new? [
                  ;print (word (who + 1) " is forming new")
                  cancel-current-coalition
                  set forming-new? false
                ]

                ;define o líder
                set coalition-leader meA
                set current-coalition newCoalition

                ;atualiza o valor da coalizão
                set coalition-value vC

                ;atualiza a cor da coalizão
                set coalition-color (item coalition-leader colors)
                set color coalition-color
                ifelse color mod 10 <= 3
                  [ set label-color white ]
                  [ set label-color black ]

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
            if is-turtle? ? [
              ask ? [
                set inbox lput msg inbox
              ]
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
            if is-turtle? ? [
              ask ? [
                set inbox lput msg inbox
              ]
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
          if is-turtle? ? [
            ask ? [
              set inbox lput msg inbox
            ]
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

        ;invitation -----------------------------------------------------------------
        if tp = 1 [ ;convite
          let la item 1 ? ;leader-agent
          let c item 2 ? ;coalition
          let vC item 3 ? ;coalition-value

          set invitations-received lput (list la c vC) invitations-received
        ]

        ;reply ----------------------------------------------------------------------
        if tp = 2 [ ;resposta
          let rem item 1 ? ;remetente
          let c item 2 ? ;coalition
          let resp item 3 ? ;resposta (1=sim, 2=não)

          set invitations-replies lput (list rem c resp) invitations-replies
        ]

        ;cancelling -----------------------------------------------------------------
        if tp = 3 [ ;cancelamento de convite
          if not empty? invitation-selected [
            if (item 1 ?) = (item 1 invitation-selected) [
              ;remove o convite selecionado da lista
              set invitation-selected []
            ]
          ]
        ]

        ;coalition finished ---------------------------------------------------------
        if tp = 4 [ ;coalizão desmanchada
          let rem item 1 ? ;remetente

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

                    ;MAGS
                    set forming-new? false
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

        ;final reply ----------------------------------------------------------------
        if tp = 5 [
          let rem item 1 ? ;remetente
          let c item 2 ? ;coalition
          let resp item 3 ? ;resposta (1=sim, 2=não)

          set final-replies lput (list rem c resp) final-replies
        ]

        ;----------------------------------------------------------------------------
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
    if ;MAGS in-coalition? = false and
       empty? invitation-selected and
       waiting-for-replies? = false and
       waiting-final? = false and
       ticks < departure-time - 5
    [
      ;if who = 9 [ print "ok"]
      ;MAGS
      ;singleton agents always perform this procedure.
      ;agents that are in coalitions perform this procedure with a given probability.
      if in-coalition? = false or
         (in-coalition? = true and allow-check-new? and not forming-new? and random-float 1 < 1)
      [

        set coalitions []
        set choosen-coalition []

        let meWho who + 1
        let meA self
        let neighborhoodA neighborhood
        let matrizCoalizoesParesAB []

        ;get current coalition of each neighbour (remove duplicates)
        let nToConsider neighborhood
        let listaC []
        foreach nToConsider [
          ask ? [
            set listaC lput current-coalition listaC
          ]
        ]
        set listaC remove-duplicates listaC

        ;remove coalitions that have non-neighbours of WHO
        let remover []
        let vizinhos []
        foreach neighborhood [
          ask ? [
            set vizinhos lput (who + 1) vizinhos
          ]
        ]
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

        ;if any of the neighboring coalitions remain feasible with WHO, then select the best one for request permission
        ifelse not empty? listaC [

          ;busca o valor de cada coalizão
          foreach listaC [

            ;MAGS - energy price on current neighbour's coalition
            let vCur getEnergyPriceOnCoalition ?

            set ? (sort-by < (lput meWho ?))
            ;let v getCoalitionValue ?

            ;MAGS - energy price on neighbour's coalition after WHO joins it
            let vNew getEnergyPriceOnCoalition ?

            if is-turtle? (turtle ((first ?) - 1))[
              ask (turtle ((first ?) - 1)) [
                ;if v <= coalition-value [
                ;MAGS
                if vNew <= vCur [
                  set vNew -100;
                ]
              ]
            ]
            if vNew != -100 [
              set coalitions lput (list ? vNew) coalitions
            ]
          ]

          ;ordena as coalizões pelo valor
          set coalitions (sort-by [ (last ?1) > (last ?2) ] coalitions)

          ;inicia o processo de convidar os vizinhos
          ifelse not empty? coalitions [
            invite-neighbors

          ]
          [
            if in-coalition? = false [;MAGS - agents in coalitions do not need to worry about stucking
              set n-last-tries n-last-tries + 1
            ]
          ]

        ]
        [
          if in-coalition? = false [;MAGS - agents in coalitions do not need to worry about stucking
            set n-last-tries n-last-tries + 1
          ]
        ]

        ;validations to avoid deadlocks----------------
        ;MAGS - validation not performed by agents already in coalitions
        if in-coalition? = false [
          if n-last-tries > 3 [
            set in-loop? true
            set n-last-tries 0
          ]

          set last-tries lput choosen-coalition last-tries

          ifelse length last-tries = 4 [
            set last-tries remove-item 0 last-tries
            ifelse length (remove-duplicates last-tries) = 1
            [ set in-loop? true ]
            [ set in-loop? false ]
          ]
          [
            set in-loop? false
          ]
        ]
        ;----------------------------------------------

      ]
    ]
  ]

end

to invite-neighbors

  ;selects the best coalition found
  set choosen-coalition first (first coalitions) ;the first is better (sorted list)
  ;let vC last (first coalitions)

  ;MAGS
  let pC last (first coalitions)
  let pCurr getEnergyPriceOnCoalition current-coalition

  ;MAGS
  if not allow-check-new? or (allow-check-new? and pC > pCurr) [

    ;envia mensagem para o lider pedindo para entrar na coalizão
    let leader (first choosen-coalition) - 1
    if leader = who [ set leader (item 1 choosen-coalition) - 1 ]
    let msg (list 1 who choosen-coalition pC);[tipo sender coalition coalition-value]
    if is-turtle? (turtle leader) [
      ask turtle leader [
        set inbox lput msg inbox
      ]
    ]

    ;activate waiting flag
    set waiting-for-replies? true

    ;MAGS
    if in-coalition? = true [
      set forming-new? true
    ]

    show-monitoring who (word "[1]Escolheu " choosen-coalition ": v(C)=" (getCoalitionValue choosen-coalition) ", p(C)="(getEnergyPriceOnCoalition choosen-coalition))

  ]

end

to-report coalitionName2coalitionNumber [ coalition ]
  let c []
  foreach coalition [
    ask ? [ set c lput (who + 1) c ]
  ]
  report c
end

to-report getCoalitionValueByID [s id]
  report getCoalitionValue (findCoalition s id)
end

to-report getCoalitionValue [coalition]
  ;report distribution:V2G coalition arture-]) p gamma delta epsilon constante

  ;MAGS
  let dticks ticks
  ;In closed world, we do not consider the ticks, since all agents will enter in the begining and last at least until the end of the first half-hour time-slot.
  ;This modification was required to better compare this approach against IP
  if not open-world?
    [ set dticks 0 ]
  let v (distribution:Similarity coalition ([departure-time - dticks] of turtles with [member? (who + 1) coalition]) epsilon p normalizing-constant constante false) ;energy price
  let Wc (length coalition) * 3.3
  ;report precision (v * Wc) 3 ;coalition value
  report v * Wc ;coalition value
end

;MAGS - return the price per energy unit on coalition
to-report getEnergyPriceOnCoalition [coalition]
  let vC getCoalitionValue coalition

  let Wc (length coalition) * 3.3
  if Wc = 0 [ report 0]

  let pC vC / Wc

  report pC
end

;MAGS
to-report getCSValue [CS]
  let v 0
  foreach CS [
    set v v + (getCoalitionValue ?)
  ]
  report v
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

;MAGS
to-report check-reductions [coalition]
  if not usa-proc? [ report coalition ]
  ;falta tratar o caso em que o líder pode ser o pior (talvez o líder deva ser o de maior departure-time)
  ;falta incluir essa procedure no process-invitations, e permitir que o líder remova agentes antigos (que estão na coalizão atual e não estão pedindo para entrar) da coalizão
  let bestC []
  let bestV -1

  let auxC coalition
  let auxV getEnergyPriceOnCoalition auxC

  while [auxV > bestV] [
    set bestV auxV
    set bestC auxC

    let lower min [departure-time] of turtles with [member? (who + 1) auxC]
    let toRem [who + 1] of turtles with [member? (who + 1) auxC and departure-time = lower]

    foreach toRem [
      set auxC remove ?  auxC
    ]

    set auxV getEnergyPriceOnCoalition auxC

  ]
  report bestC
end

to-report get-reductions [CL]
  if not usa-red? [report CL]

  let new []

  foreach CL [
    set new lput (check-reductions ?) new
  ]

  report new

end

;MAGS
;kill agents whose departure time has been achieved
to kill-departure
  let cnt 0
  ask turtles with [departure-time = ticks] [
    set cnt cnt + 1
    ;print "kill"
    kill-agent who
  ]
  if cnt > 0 [
    ;print cnt
    ;show (word "killed " cnt)
    foreach n-values cnt [?] [
      create-new-agent
      ;print "created"
    ]
  ]
end

to kill-random
  if one-of turtles with [in-coalition? = true] != nobody [
    ask one-of turtles with [in-coalition? = true] [
      kill-agent who
    ]
  ]
end

to kill-agent [id]
  ask turtle id [

    cancel-current-coalition

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
end

to cancel-current-coalition
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
        if is-turtle? turtle (? - 1) [
          ask turtle (? - 1) [
            set current-coalition (list (who + 1))
            set coalition-value getCoalitionValue current-coalition
            set coalition-leader who
            set coalition-color (item who colors)
            set in-coalition? false
            set time-in-coalition lput (ticks - last-join-unjoin) time-in-coalition
            set last-join-unjoin ticks
            set color (item coalition-leader colors)

            ;MAGS
            set forming-new? false
          ]
        ]
      ]
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
  ;get CS
  let CS []
  let leaders remove-duplicates [coalition-leader] of turtles
  foreach leaders [
    set CS lput (sort ([who + 1] of turtles with [coalition-leader = ?])) CS
  ]
  set CS sort-by [length ?1 < length ?2 or (length ?1 = length ?2 and (first ?1) < (first ?2))] CS
  set CS-atual CS

  ;calculate CS's value
  let prevVCS VCS
  set VCS 0
  ;foreach CS [
  ;  let C (sort ?)
  ;  ;set VCS VCS + ([coalition-value] of turtle ((first C) - 1))
  ;  set VCS VCS + (getCoalitionValue ?)
  ;]
  foreach leaders [
    if is-turtle? turtle ? [
      set VCS VCS + [coalition-value] of turtle ?
    ]
  ]

  ;check whether the CS is stable (no changes over the last 10 iterations)
  if not is-list? last-CSs [ set last-CSs [] ]
  set last-CSs lput CS-atual last-CSs
  if length last-CSs >= 10 [
    set last-CSs remove-item 0 last-CSs
    ifelse length (remove-duplicates last-CSs) = 1
      [ set is-stable? true ]
      [ set is-stable? false ]

  ]

  ;print the CS and value
  if show-CS and (VCS != prevVCS or ticks = 0) [
    let feasible? true
    foreach CS-atual [ if not is-feasible? ? [set feasible? false]]
    ifelse feasible?
      [show (word "CS = " CS ", V(CS) = " VCS " (feasible)")]
      [show (word "CS = " CS ", V(CS) = " VCS " (NOT feasible)")]
  ]
end

to teste
  let n 10
  set usa-proc? true
  foreach n-values n [? + 1] [
    setup
    while [ticks < max-ticks] [ go-forever ]
    export-plot "V(CS)" (word "run" ? "_red.csv")
  ]
  set usa-proc? false
  foreach n-values n [? + 1] [
    setup
    while [ticks < max-ticks] [ go-forever ]
    export-plot "V(CS)" (word "run" ? "_nored.csv")
  ]
end

to-report teste2
  if not usa-red?
    [ report "não" ]

  print "abc"
  report "sim"
end

;MAGS
to generate-all-scenarios

  if not user-yes-or-no? "Are you sure you want to DELETE all saved scenarios, and create NEW ones?"
    [ stop ]
  if not user-yes-or-no? "You need to create one directory for each set of experiments, e.g., 'agentes10' for experiments with 10 agents, and so on, until agentes20. Have you already created these directories?"
    [ stop ]

  set-current-directory "saved-scenarios"

  ;from 10 to 20 agents
  foreach n-values 11 [? + 10] [

    set n-of-agents ?

    let dir (word ? "agentes")

    ;check whether the directories were created
    if file-exists? dir [
      set-current-directory dir

      ;30 scenarios
      foreach n-values 30 [? + 1] [

        ;create the scenario
        setup

        ;save the scenario-------
        let name ""
        ifelse ? < 10
          [ set name (word "0" ?) ]
          [ set name (word ?) ]

        if file-exists? name
          [ file-delete name ]

        file-open name
        foreach n-values n-of-agents [?] [
          ask turtle ? [
            file-print (list xcor ycor departure-time)
          ]
        ]
        file-close
        ;-------------------------

      ]
      set-current-directory ".."
    ]
  ]
  set-current-directory ".."
end

;MAGS - to be used by the other CSG algorithms in Java
to generate-constraints-list-all-scenarios

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

      ;print list of constraints
      print (word n-of-agents ";" ? ";" generate-constraints-list)

      set-current-directory dir
    ]
    set-current-directory ".."
  ]
  set-current-directory ".."
end

;MAGS - to be used by the other CSG algorithms in Java
to generate-departure-time-list-all-scenarios

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

      ;print list of constraints
      print (word n-of-agents ";" ? ";" generate-departure-time-list)

      set-current-directory dir
    ]
    set-current-directory ".."
  ]
  set-current-directory ".."
end

;MAGS - to be used by the other CSG algorithms in Java
to-report generate-constraints-list

  ;check constraints
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

  ;generate string of constraints
  let str ""
  foreach const [
    set str (word str (first ?))
    foreach (last ?) [
      set str (word str "," ?)
    ]
    set str (word str ";")
  ]

  ;return the string
  report str
end

;MAGS - to be used by the other CSG algorithms in Java
to-report generate-departure-time-list
  let str ""
  foreach sort [who] of turtles [
    if str != "" [ set str (word str ",") ]
    set str (word str ([departure-time] of turtle ?))
  ]
  report str
end

to generate-constraints-list_JBCS
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
  ;aux removed from facil button
  let aux ""
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

to reset-graph
  ask turtles [
    set inbox []
    set coalitions []
    set coalition-color (item who colors)
    set coalition-leader who
    set current-coalition (list (who + 1))
    set coalition-value (getCoalitionValue current-coalition)
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

    ;MAGS
    set forming-new? false
  ]

  set is-stable? false
  set VCS 0

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
  ;if n-of-agents >= 100 [
  ;  user-message "The maximum number of agents was reached."
  ;  stop
  ;]
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

      ;MAGS
      set departure-time gen-departure-time
      set forming-new? false

      ;-----------------------
      ;cria os links
      let meA self
      let n []
      let nG []

      ;MAGS
      ;let tx xcor
      ;let ty ycor
      let dt departure-time

      ;cria links entre agentes que podem formar coalizão
      ;create-links-with other turtles with [sqrt (((xcor - tx) ^ 2) + ((ycor - ty) ^ 2)) < alpha] [ set color gray ]
      ;MAGS
      create-links-with other turtles with [abs (dt - departure-time) <= alpha] [ set color gray ]

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
end

to-report is-there-working-agents?
  if is-stable? [ report false ]
  ifelse any? turtles with [ not in-coalition? and not in-loop? and not empty? neighborhood ]
      or any? turtles with [ forming-new? ];MAGS
    [ report true ]
    [ report false ]
end

to save-scenario
  set-current-directory (word "saved-scenarios//" n-of-agents "agentes")
  file-open user-new-file
  foreach n-values n-of-agents [?] [
    ask turtle ? [
      file-print (list xcor ycor departure-time)
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

  set-colors

  set-default-shape turtles "circle"

  while [ not file-at-end? ] [
      let str read-from-string file-read-line
      let x item 0 str
      let y item 1 str
      let dt item 2 str
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

          ;MAGS
          set departure-time dt
          set forming-new? false
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
  ;countdown
  let ttt 3 repeat ttt [ print ttt set ttt ttt - 1 wait 1] print "go"

  print "n;Cenário;Tempo;V(CS)"
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
      print (word n-of-agents ";" ? ";" go-n-times-exp)

      ;salva a imagem, se desejado
      ;if export-views? [export-view (word "img-exp//" n-of-agents"-scenario" filename)]

      set-current-directory dir
    ]
    set-current-directory ".."
    ;show ""
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

    ;let inst (coalition-value * 3.3 / 60) ;considerando que a bateria de um EV tem 3.3kWh

    ;MAGS - como no coalition-value já está embutida a quantidade de energia (3.3 * |C|), então ao dividir por |C| obtém-se a parte de um agente,
    ;e ao dividir por 60 obtém-se o valor por minuto
    let inst (coalition-value / (length current-coalition) / 60)
    ;print (word (who + 1) " = " inst)

    set accumulated-value accumulated-value + inst
    ;if in-coalition? [
      set avg-payoff avg-payoff + inst;(accumulated-value / ((get-agents-stat-info who 4) - (get-agents-stat-info who 3)))
      set cnt cnt + 1
    ;]
    set-agents-stat-info who 5 accumulated-value
  ]
  if cnt > 0
    [ set avg-payoff avg-payoff / cnt ]
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
    if getEnergyPriceOnCoalition ? > bestV [
      set best ?
      set bestV getEnergyPriceOnCoalition ?
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
  if show-monitoring? [
    if member? ag [3 11 14] [
      show (word (ag + 1) ": " str)
    ]
  ]
end

;MAGS
to test-dep-time
  foreach n-values 100 [?] [
    print gen-departure-time
  ]
end

;MAGS
;return a random departure time based on a normal distribution
to-report gen-departure-time

  ;in 30-minutes timeslots
  let avg 8   ;4 hours
  let sd 4    ;2 hours
  let minv 1  ;0.5 hour
  let maxv 16 ;8 hours

  ;normal
  ;let v gen-departure-time-value avg sd minv maxv 3
  ;uniform
  let v (random maxv - minv + 1) + minv

  report ticks + (30 * round v);the value is multiplied by 30 to provide the result in minutes (instead of 30-minutes timeslots)

end

;MAGS
;generate the random value for departure time
;if the value is out of a limit [minv...maxv], the value is regenerated up to TRIES times
to-report gen-departure-time-value [avg sd minv maxv tries]
  let v random-normal avg sd
  if v < minv or v > maxv [
    set tries tries - 1
    ;try again until TRIES tries
    ifelse tries > 0 [
      set v gen-departure-time-value avg sd minv maxv tries
    ]
    [;if the limit of tries were achieved, enforce values to the limit [minv...maxv]
      ifelse v < minv
        [ report minv ]
        [ if v > maxv [ report maxv ] ]
    ]
  ]
  report v
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
10
10
84
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
85
10
149
43
step
;print (word \"------------------------------------\\n\" ticks \"\\n\")\nGo\n;let i (list 0 2 3 5)\n;let i n-values 10 [?]\n;foreach i [ask turtle ? [print (word ? \"\\n\" choosen-coalition \"\\n\" coalitions \"\\n\" inbox \"\\n\")]]
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
50
85
190
145
alpha
60
1
0
Number

BUTTON
1120
265
1190
298
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

SLIDER
10
45
182
78
n-of-agents
n-of-agents
2
100
50
1
1
NIL
HORIZONTAL

BUTTON
1120
300
1290
333
generate-constraints-list
print generate-constraints-list
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
100
375
595
525
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

SWITCH
1120
335
1237
368
show-CS
show-CS
1
1
-1000

BUTTON
10
275
127
308
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
48
251
81
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
130
260
262
293
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
130
296
265
329
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
1340
385
1450
445
repetitions
1
1
0
Number

BUTTON
1120
370
1260
403
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
0
1
0
Number

INPUTBOX
936
82
1097
142
p_l
0
1
0
Number

SWITCH
955
155
1098
188
open-world?
open-world?
0
1
-1000

PLOT
600
375
1095
525
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
600
685
1095
835
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
10
160
253
193
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

PLOT
600
530
1095
680
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
100
530
596
680
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
98
685
594
835
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
150
10
260
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
600
841
1095
991
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
1100
908
1261
953
avg-agents-in-coalition
100 - (avg-agents-out / ticks)
17
1
11

PLOT
98
841
594
991
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
98
996
594
1146
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
20
565
96
610
avg-time-in-coalition
avg-time-in-coalition / ticks
3
1
11

MONITOR
1101
598
1215
643
avg-time-to-join
avg-time-to-join / ticks
3
1
11

BUTTON
10
198
253
231
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

INPUTBOX
1102
150
1263
210
normalizing-constant
10000
1
0
Number

SWITCH
605
165
785
198
allow-check-new?
allow-check-new?
0
1
-1000

SWITCH
605
200
708
233
usa-if?
usa-if?
0
1
-1000

SWITCH
605
275
724
308
usa-red?
usa-red?
1
1
-1000

SWITCH
1120
230
1302
263
show-monitoring?
show-monitoring?
1
1
-1000

SWITCH
605
310
732
343
usa-proc?
usa-proc?
1
1
-1000

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
<experiments>
  <experiment name="closed_world" repetitions="1" runMetricsEveryStep="false">
    <setup>run-experiments-closed-world</setup>
    <enumeratedValueSet variable="repetitions">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gamma">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-of-agents">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_e">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-monitoring?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usa-if?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="allow-check-new?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="1440"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-CS">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="constante">
      <value value="12345"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="normalizing-constant">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usa-red?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="open-world?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="epsilon">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p_l">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="delta">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
1
@#$#@#$#@
