
(sorry this doc is in French only, but everybody should understand the ponctuation :)

**IP**
  * private network 10.0.0.0/8
  * normalisation des IPs : 
    * **00001010.TTCCCCRR (16 bits partie commune)**
      * 8 bits (le 10.x.x.x/8)
      * 2 bits pour le type [**TT**]
        * 01 = cloud
      * 4 bits pour le numéro du cloud [**CCCC**]
        * 0001 = primary
        * 1xxx = locally wired
      * 2 bits pour le type de réseau [**RR**]
        * 01 = interfaces tunnel GRE
        * 10 = interfaces du bridge LXC / VMs
    * **00001010.TTCCCC01.AAAAAAAB.BBBBBBNN /30 (GRE)**
      * 7 bits numéro du noeud A (A<B) [**AAAAAAA**]
      * 7 bits numéro du noeud B (A<B) [**BBBBBBB**]
      * 2 bits pour indiquer notre côté [**NN**]
        * 00 = interface GRE côté A (au numéro inférieur)
        * 01 = interface GRE côté B (au numéro supérieur)

    * **00001010.TTCCCC10.PPPPPPPL.LLLLLLLL /23 (LXC)**
      * 7 bits pour le numéro du noeud [**PPPPPPP**]
      * 9 bits pour le numéro de l'interface/LXC sur noeud physique [**LLLLLLLLL**]
        * n°1 = host bridge (10.x.x.1)
        * n°2,3,4 =  LXC container (10.x.x.2+)

  * Examples cloud "primary" (1) à 4 noeuds, 2 contains LXC chacun
    * Physical node 1
      * Interface GRE vers node 2
        * 00001010.01000101.00000010.00001000 soit **10.69.2.8 /30**
      * Interface GRE vers node 3
        * 00001010.01000101.00000010.00001100 soit **10.69.2.12 /30**
      * Interface GRE vers node 4
        * 00001010.01000101.00000010.00010000 soit **10.69.2.16 /30**
      * LXC bridge
        * 00001010.01000110.00000010.00000001 soit **10.70.2.1 /23**
      * LXC 1 : eth0
        * 00001010.01000110.00000010.00000010 soit **10.70.2.2 /23**
      * LXC 2 : eth0
        * 00001010.01000110.00000010.00000011 soit **10.70.2.3 /23**
    * Physical node 2
      * Interface GRE vers node 1
        * 00001010.01000101.00000010.00001001 soit **10.69.2.9 /30**
      * Interface GRE vers node 3
        * 00001010.01000101.00000100.00001100 soit **10.69.4.12 /30**
      * Interface GRE vers node 4
        * 00001010.01000101.00000100.00010000 soit **10.69.4.16 /30**
      * LXC bridge
        * 00001010.01000110.00000100.00000001 soit **10.70.4.1 /23**
      * LXC 1 : eth0
        * 00001010.01000110.00000100.00000010 soit **10.70.4.2 /23**
      * LXC 2 : eth0
        * 00001010.01000110.00000100.00000011 soit **10.70.4.3 /23**
    * Physical node 3
      * Interface GRE vers node 1
        * 00001010.01000101.00000010.00001101 soit **10.69.2.13 /30**
      * Interface GRE vers node 2
        * 00001010.01000101.00000100.00001101 soit **10.69.4.13 /30**
      * Interface GRE vers node 4
        * 00001010.01000101.00000110.00010000 soit **10.69.6.16 /30**
      * LXC bridge
        * 00001010.01000110.00000110.00000001 soit **10.70.6.1 /23**
    * Physical node 4
      * Interface GRE vers node 1
        * 00001010.01000101.00000010.00010001 soit **10.69.2.17 / 30**
      * Interface GRE vers node 2
        * 00001010.01000101.00000100.00010001 soit **10.69.4.17 /30**
      * Interface GRE vers node 3
        * 00001010.01000101.00000110.00010001 soit **10.69.6.17 /30**
      * LXC bridge
        * 00001010.01000110.00001000.00000001 soit **10.70.8.1 /23**

  * Autrement dit :
    * 14 bits identifient le cloud n°CCCCC : 00001010.01CCCC -- 10.{64+CCCC}
    * 16 bits identifient un domaine (GRE ou LXC) dans un cloud
    * 23 bits identifient un réseau bridge sur un noeuds physique
    * 30 bits identifient un réseau GRE entre 2 noeuds physiques

**Interfaces**
  * cloud interfaces (IFNAMSIZ == 16 incluant \0)
    * GRE tunnel
      * ex: nc4t-11-12
        * nc = nef cloud
        * 4 = cloud number 4
        * t = GRE tunnel
        * 11 = node number of current host
        * 12 = node bumber of target host
    * LXC bridge
      * ex: nc4x-11
        * nc = nef cloud
        * 4 = cloud number 4
        * x = LXC
        * 11 = node number
    * LXC pairs hosts points
      * ex: nc4x-11.2
        * nc4x-11 : same as LXC bridge
        * 2 : interface number (bridge/gateway is 1, LXC containers start at 2)
