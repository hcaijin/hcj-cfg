#!/bin/bash
#脚本文件名: tc2
#########################################################################################
#用TC(Traffic Control)解决ADSL宽带速度技术 Ver. 1.0        by KindGeorge 2004.12.27        #
#########################################################################################
#此脚本经过实验通过，更多的信息请参阅http://lartc.org
#tc+iptables+HTB+SFQ
#
#一.什么是ADSL? ADSL（Asymmetric Digital Subscriber Loop，非对称数字用户环路）
#用最简单的话的讲,就是采用上行和下行不对等带宽的基于ATM的技术.
#举例,我们最快的其中一条ADSL带宽是下行3200Kbit,上行只有320Kbit.带宽通常用bit表示.
#
#1、下行3200K 意味着什么？
#因为 1Byte=8Bit ,一个字节由8个位(bit)组成,一般用大写B表示Byte,小写b表示Bit.
#所以 3200K=3200Kbps=3200K bits/s=400K bytes/s.
#2、 上行320K 意味着什么？
# 320K=320Kbps=320K bits/s=40K bytes/s.
#就是说,个人所能独享的最大下载和上传速度,整条线路在没任何损耗,最理想的时候,
#下载只有400K bytes/s,上传只有最大40K bytes/s的上传网速.
#这些都是理想值,但现实总是残酷的,永远没有理想中那么好.至少也有损耗,何况内部网有几十台
#电脑一起疯狂上网.
#
#3.ADSL上传速度对下载的影响
#(1)TCP/IP协议规定，每一個封包，都需要有acknowledge讯息的回传，也就是说，传输的资料，
#需要有一个收到资料的讯息回复，才能决定后面的传输速度，並决定是否重新传输遗失
#的资料。上行的带宽一部分就是用來传输這些acknowledge(确认)資料模鄙闲懈涸毓?
#大的时候，就会影响acknowledge资料的传送速度，并进而影响到下载速度。这对非对称
#数字环路也就是ADSL这种上行带宽远小于下载带宽的连接来说影响尤为明显。
#(2)试验证明，当上传满载时，下载速度变为原来速度的40％，甚至更低.因为上载文件(包括ftp
#上传,发邮件smtp),如果较大,一个人的通讯量已经令整条adsl变得趋向饱和,那么所有的数据
#包只有按照先进先出的原则进行排队和等待.这就可以解释为什么网内其中有人用ftp上载文件,
#或发送大邮件的时候,整个网速变得很慢的原因。
#
#二.解决ADSL速度之道
#1. 为解决这些速度问题,我们按照数据流和adsl的特点,对经过线路的数据进行了有规则的分流.
#把本来在adsl modem上的瓶颈转移到我们linux路由器上,可以把带宽控制的比adsl modem上的小一点,
#这样我们就可以方便的用tc技术对经过的数据进行分流和控制.
#我们的想象就象马路上的车道一样,有高速道,还有小车道,大车道.需要高速的syn,ack,icmp等走
#高速道,需要大量传输的ftp-data,smtp等走大车道,不能让它堵塞整条马路.各行其道.
#2. linux下的TC(Traffic Control)就有这样的作用.只要控制得当,一定会有明显的效果.
#tc和iptables结合是最好的简单运用的结合方法.
#我们设置过滤器以便用iptables对数据包进行分类,因为iptables更灵活，而且你还可以为每个规则设
#置计数器. iptables用mangle链来mark数据包,告诉了内核，数据包会有一个特定的FWMARK标记值(hanlde x fw)，
#表明它应该送给哪个类( classid x : x),而prio是优先值,表明哪些重要数据应该优先通过哪个通道.
#首先选择队列,cbq和htb是不错的选择,经过实验,htb更为好用,所以以下脚本采用htb来处理
#3. 一般系统默认的是fifo的先进先出队列,就是说数据包按照先来先处理的原则,如果有一个大的数
#据包在前面,#那么后面的包只能等前面的发完后才能接着发了,这样就算后面即使是一个小小的ack包,
#也要等待了,这样上传就影响了下载,就算你有很大的下载带宽也无能为力.
#HTB(Hierarchical Token Bucket, 分层的令牌桶)
#更详细的htb参考 http://luxik.cdi.cz/~devik/qos/htb/
#HTB就象CBQ一样工作，但是并不靠计算闲置时间来整形。它是一个分类的令牌桶过滤器。它只有很少的参数
#他的分层(Hierarchical)能够很好地满足这样一种情况：你有一个固定速率的链路，希望分割给多种不同的
#用途使用,为每种用途做出带宽承诺并实现定量的带宽借用。
#4. 结构简图:
#~~~~~~ |
#~~~~~ __1:__
#~~~~ |~~~~~ |
#~  _ _ _1:1~~~ 1:2_ _ _ _ _ _ _ _
#  | ~ ~ |  ~ ~ ~ |  ~ ~ | ~ ~ | ~ ~ |
#1:11~1:12~~1:21~1:22~1:23~1:24
#优先顺序是1:11 1:12   1:21 1:22  1:23 1:24
#
#--------------------------------------------------------------------------------------------
#5.根据上面的例子,开始脚本   
#通常adsl用pppoe连接,的得到的是ppp0,所以公网网卡上绑了ppp0
#关于参数的说明
#(1)rate: 是一个类保证得到的带宽值.如果有不只一个类,请保证所有子类总和是小于或等于父类.
#(2)ceil: ceil是一个类最大能得到的带宽值.
#(3)prio: 是优先权的设置,数值越大,优先权越小.如果是分配剩余带宽,就是数值小的会最优先取得剩余
#的空闲的带宽权.
#具体每个类要分配多少rate,要根据实际使用测试得出结果.
#一般大数据的话,控制在50%-80%左右吧,而ceil最大建议不超过85%,以免某一个会话占用过多的带宽.
#rate可按各类所需分配,
#1:11 是很小而且最重要的数据包通道,当然要分多点.甚至必要时先全部占用,不过一般不会的.所以给全速.
#1:12 是很重要的数据道,给多点,最少给一半,但需要时可以再多一点.
#rate 规划 1:2 = 1:21 + 1:22 + 1:23 + 1:24  一般总数在50%-80%左右
#1:21 http,pop是最常用的啦,为了太多人用,而导致堵塞,我们不能给得太多,也不能太少.
#1:22 我打算给smtp用,优先低于1:21 以防发大的附件大量占用带宽,
#1:23 我打算给ftp-data,和1:22一样,很可能大量上传文件,所以rate不能给得太多,而当其他有剩时可以给大些,ceil设置大些
#1:24 是无所谓通道,就是一般不是我们平时工作上需要的通道了,给小点,防止这些人在妨碍有正常工作需要的人
#上行 uplink 320K,设置稍低于理论值
DEV="wlp3s0"
UPLINK=2000
#下行downlink 3200 k 大概一半左右,以便能够得到更多的并发连接
DOWNLINK=10000

echo "==================== Packetfilter and Traffic Control 流量控制 By 网络技术部 Ver. 1.0===================="

start_routing() {
        echo -n "队列设置开始start......"
        #1.增加一个根队列，没有进行分类的数据包都走这个1:24是缺省类:
        tc qdisc add dev $DEV root handle 1: htb default 24
        #1.1增加一个根队下面主干类1: 速率为$UPLINK k
        tc class add dev $DEV parent 1: classid 1:1 htb rate ${UPLINK}kbit ceil ${UPLINK}kbit prio 0

        #1.1.1 在主干类1下建立第一叶子类,这是一个最高优先权的类.需要高优先和高速的包走这条通道,比如SYN,ACK,ICMP等
        tc class add dev $DEV parent 1:1 classid 1:11 htb rate $[$UPLINK]kbit ceil ${UPLINK}kbit prio 1
        #1.1.2 在主类1下建立第二叶子类 ,这是一个次高优先权的类。比如我们重要的crm数据.
        tc class add dev $DEV parent 1:1 classid 1:12 htb rate $[$UPLINK-800]kbit ceil ${UPLINK-50}kbit prio 2

        #1.2 在根类下建立次干类 classid 1:2 。此次干类的下面全部优先权低于主干类,以防重要数据堵塞.
        tc class add dev $DEV parent 1: classid 1:2 htb rate $[$UPLINK-1000]kbit prio 3

        #1.2.1 在次干类下建立第一叶子类,可以跑例如http,pop等.
        tc class add dev $DEV parent 1:2 classid 1:21 htb rate 100kbit ceil $[$UPLINK-1000]kbit prio 4

        #1.2.2 在次干类下建立第二叶子类。不要太高的速度,以防发大的附件大量占用带宽,例如smtp等
        tc class add dev $DEV parent 1:2 classid 1:22 htb rate 30kbit ceil $[$UPLINK-1100]kbit prio 5

        #1.2.3 在次干类下建立第三叶子类。不要太多的带宽,以防大量的数据堵塞网络,例如ftp-data等,
        tc class add dev $DEV parent 1:2 classid 1:23 htb rate 15kbit ceil $[$UPLINK-1300]kbit prio 6

        #1.2.4 在次干类下建立第四叶子类。无所谓的数据通道,无需要太多的带宽,以防无所谓的人在阻碍正务.
        tc class add dev $DEV parent 1:2 classid 1:24 htb rate 5kbit ceil $[$UPLINK-1900]kbit prio 7

        #在每个类下面再附加上另一个队列规定,随机公平队列(SFQ)，不被某个连接不停占用带宽,以保证带宽的平均公平使用：
        #SFQ(Stochastic Fairness Queueing，随机公平队列),SFQ的关键词是“会话”(或称作“流”) ，
        #主要针对一个TCP会话或者UDP流。流量被分成相当多数量的FIFO队列中，每个队列对应一个会话。
        #数据按照简单轮转的方式发送, 每个会话都按顺序得到发送机会。这种方式非常公平，保证了每一
        #个会话都不会没其它会话所淹没。SFQ之所以被称为“随机”，是因为它并不是真的为每一个会话创建
        #一个队列，而是使用一个散列算法，把所有的会话映射到有限的几个队列中去。
        #参数perturb是多少秒后重新配置一次散列算法。默认为10
        tc qdisc add dev $DEV parent 1:11 handle 111: sfq perturb 5
        tc qdisc add dev $DEV parent 1:12 handle 112: sfq perturb 5
        tc qdisc add dev $DEV parent 1:21 handle 121: sfq perturb 10
        tc qdisc add dev $DEV parent 1:22 handle 122: sfq perturb 10
        tc qdisc add dev $DEV parent 1:23 handle 133: sfq perturb 10
        tc qdisc add dev $DEV parent 1:24 handle 124: sfq perturb 10
        echo "队列设置成功.done."
        echo -n "设置包过滤 Setting up Filters......"
        #这里设置过滤器,handle 是iptables作mark的值,让被iptables 在mangle链做了mark的不同的值选择不同的通
        #道classid,而prio 是过滤器的优先级别.
        tc filter add dev $DEV parent 1:0 protocol ip prio 1 handle 1 fw classid 1:11
        tc filter add dev $DEV parent 1:0 protocol ip prio 2 handle 2 fw classid 1:12
        tc filter add dev $DEV parent 1:0 protocol ip prio 3 handle 3 fw classid 1:21
        tc filter add dev $DEV parent 1:0 protocol ip prio 4 handle 4 fw classid 1:22
        tc filter add dev $DEV parent 1:0 protocol ip prio 5 handle 5 fw classid 1:23
        tc filter add dev $DEV parent 1:0 protocol ip prio 6 handle 6 fw classid 1:24
        echo "设置过滤器成功.done."

                

########## downlink ##########################################################################
#6. 下行的限制:
#设置入队的规则,是因为把一些经常会造成下载大文件的端口进行控制,不让它们来得太快,导致堵塞.来得太快
#的就直接drop,就不会浪费和占用机器时间和力量去处理了.
#(1). 把下行速率控制在大概1000-1500k左右,因为这个速度已经足够用了,以便能够得到更多的并发下载连接

tc qdisc add dev $DEV handle ffff: ingress

tc filter add dev $DEV parent ffff: protocol ip prio 50 handle 8 fw police rate ${DOWNLINK}kbit burst 10k drop flowid :8
}
#(2).如果内部网数据流不是很疯狂的话,就不用做下载的限制了,用#符号屏蔽上面两行即可.
#(3).如果要对任何进来数据的数据进行限速的话,可以用下面这句:
#tc filter add dev $DEV parent ffff: protocol ip prio 10 u32 match ip src 0.0.0.0/0 police rate ${DOWNLINK}kbit burst 10k drop flowid :1

###############################################################################################
#7. 开始给数据包打标记，往PREROUTING链中添加mangle规则：
start_mangle() {
               
        echo -n "开始给数据包打标记......start mangle mark......"

#(1)把出去的不同类数据包(为dport)给mark上标记1--6.让它走不同的通道
#(2)把进来的数据包(为sport)给mark上标记8,让它受到下行的限制,以免速度太过快而影响全局.
#(3)每条规则下根着return的意思是可以通过RETURN方法避免遍历所有的规则,加快了处理速度
##设置TOS的处理：
#iptables -t mangle -A PREROUTING -m tos --tos Minimize-Delay -j MARK --set-mark 1
#iptables -t mangle -A PREROUTING -m tos --tos Minimize-Delay -j RETURN
#iptables -t mangle -A PREROUTING -m tos --tos Minimize-Cost -j MARK --set-mark 4
#iptables -t mangle -A PREROUTING -m tos --tos Minimize-Cost -j RETURN
#iptables -t mangle -A PREROUTING -m tos --tos Maximize-Throughput -j MARK --set-mark 5
#iptables -t mangle -A PREROUTING -m tos --tos Maximize-Throughput -j RETURN

##提高tcp初始连接(也就是带有SYN的数据包)的优先权是非常明智的：
iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j MARK --set-mark 1
iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j RETURN

######icmp,想ping有良好的反应,放在第一类吧.
iptables -t mangle -A PREROUTING -p icmp -j MARK --set-mark 1
iptables -t mangle -A PREROUTING -p icmp -j RETURN

# small packets (probably just ACKs)长度小于64的小包通常是需要快些的,一般是用来确认tcp的连接的,
#让它跑快些的通道吧.也可以把下面两行屏蔽,因为再下面有更多更明细的端口分类.
#iptables -t mangle -A PREROUTING -p tcp -m length --length :64 -j MARK --set-mark 2
#iptables -t mangle -A PREROUTING -p tcp -m length --length :64 -j RETURN

#ftp放第2类,因为一般是小包, ftp-data放在第5类,因为一般是大量数据的传送.
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport ftp -j MARK --set-mark 2
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport ftp -j RETURN
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport ftp-data -j MARK --set-mark 5
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport ftp-data -j RETURN
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport ftp -j MARK --set-mark 8
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport ftp -j RETURN
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport ftp-data -j MARK --set-mark 8
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport ftp-data -j RETURN
##提高ssh数据包的优先权：放在第1类,要知道ssh是交互式的和重要的,不容待慢哦
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 22 -j MARK --set-mark 1
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 22 -j RETURN
#
##smtp邮件：放在第4类,因为有时有人发送很大的邮件,为避免它堵塞,让它跑4道吧
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 25 -j MARK --set-mark 4
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 25 -j RETURN
#iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 25 -j MARK --set-mark 8
#iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 25 -j RETURN
## name-domain server：放在第1类,这样连接带有域名的连接才能快速找到对应的地址,提高速度的一法
iptables -t mangle -A PREROUTING -p udp -m udp --dport 53 -j MARK --set-mark 1
iptables -t mangle -A PREROUTING -p udp -m udp --dport 53 -j RETURN
#
## http：放在第3类,是最常用的,最多人用的,
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 80 -j MARK --set-mark 3
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 80 -j RETURN
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 80 -j MARK --set-mark 8
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 80 -j RETURN
##pop邮件：放在第3类
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 110 -j MARK --set-mark 3
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 110 -j RETURN
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 110 -j MARK --set-mark 8
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 110 -j RETURN
## https：放在第3类
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 443 -j MARK --set-mark 3
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 443 -j RETURN
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 443 -j MARK --set-mark 8
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 443 -j RETURN
## Microsoft-SQL-Server：放在第2类,我这里认为较重要,一定要保证速度的和优先的.
#iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 1433 -j MARK --set-mark 2
#iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 1433 -j RETURN
#iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 1433 -j MARK --set-mark 8
#iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 1433 -j RETURN
## Mysql：放在第2类,较重要,一定要保证速度的和优先的.
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 3306 -j MARK --set-mark 2
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 3306 -j RETURN
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 3306 -j MARK --set-mark 8
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 3306 -j RETURN

## voip用, 提高,语音通道要保持高速,才不会断续.
#iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 1720 -j MARK --set-mark 1
#iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 1720 -j RETURN
#iptables -t mangle -A PREROUTING -p udp -m udp --dport 1720 -j MARK --set-mark 1
#iptables -t mangle -A PREROUTING -p udp -m udp --dport 1720 -j RETURN

## vpn ,用作voip的,也要走高速路,才不会断续.
#iptables -t mangle -A PREROUTING -p udp -m udp --dport 7707 -j MARK --set-mark 1
#iptables -t mangle -A PREROUTING -p udp -m udp --dport 7707 -j RETURN

## 放在第1类,因为我觉得它在我心中很重要,优先.
#iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 7070 -j MARK --set-mark 1
#iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 7070 -j RETURN

## WWW caching service：放在第3类
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 8078 -j MARK --set-mark 3
iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 8078 -j RETURN
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 8078 -j MARK --set-mark 8
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 8078 -j RETURN

##提高本地数据包的优先权：放在第1
iptables -t mangle -A OUTPUT -p tcp -m tcp --dport 22 -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -p tcp -m tcp --dport 22 -j RETURN

iptables -t mangle -A OUTPUT -p icmp -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -p icmp -j RETURN

#本地small packets (probably just ACKs)
iptables -t mangle -A OUTPUT -p tcp -m length --length :64 -j MARK --set-mark 2
iptables -t mangle -A OUTPUT -p tcp -m length --length :64 -j RETURN

# 杀掉这个网络
#iptables -t mangle -I PREROUTING 1 -s 192.168.12.1/24 -j MARK --set-mark 6
#iptables -t mangle -I PREROUTING 2 -s 192.168.12.1/24 -j RETURN

#(4). 向PREROUTING中添加完mangle规则后，用这条规则结束PREROUTING表：
##也就是说前面没有打过标记的数据包将交给1:24处理。
##实际上是不必要的，因为1:24是缺省类，但仍然打上标记是为了保持整个设置的协调一致，而且这样
#还能看到规则的包计数。

iptables -t mangle -A PREROUTING -i $DEV -j MARK --set-mark 6
echo "标记完毕! mangle mark done!"
}
#-----------------------------------------------------------------------------------------------------

#8.取消mangle标记用的自定义函数
stop_mangle() {
       
        echo -n "停止数据标记 stop mangle table......"
        ( iptables -t mangle -F && echo "ok." ) || echo "error."
}

#9.取消队列用的       
stop_routing() {
        echo -n "(删除所有队列......)"
        ( tc qdisc del dev $DEV root && tc qdisc del dev $DEV ingress && echo "ok.删除成功!" ) || echo "error."
}

#10.显示状态
status() {
        echo "1.show qdisc $DEV  (显示上行队列):----------------------------------------------"
        tc -s qdisc show dev $DEV
        echo "2.show class $DEV  (显示上行分类):----------------------------------------------"
        tc class show dev $DEV
        echo "3. tc -s class show dev $DEV (显示上行队列和分类流量详细信息):------------------"
        tc -s class show dev $DEV
        echo "说明:设置总队列上行带宽 $UPLINK k."
        echo "1. classid 1:11 ssh、dns、和带有SYN标记的数据包。这是最高优先权的类包并最先类 "
        echo "2. classid 1:12 重要数据,这是较高优先权的类。"
        echo "3. classid 1:21 web,pop 服务 "
        echo "4. classid 1:22 smtp服务 "
        echo "5. classid 1:23 ftp-data服务 "
        echo "6. classid 1:24 其他服务 "
}

#11.显示帮助
usage() {
        echo "使用方法(usage): `basename $0` [start | stop | restart | status | mangle ]"
        echo "参数作用:"
        echo "start   开始流量控制"
        echo "stop    停止流量控制"
        echo "restart 重启流量控制"
        echo "status  显示队列流量"
        echo "mangle  显示mark标记"
}

#----------------------------------------------------------------------------------------------
#12. 下面是脚本运行参数的选择的控制
#
kernel=`uname -r | awk -F . '{print $1".*"}' `
case "$kernel" in
   2.2)
      echo " (!) Error: won't do anything with 2.2.x 不支持内核2.2.x"
      exit 1
      ;;
      
   2.4|2.6|3.*)
      case "$1" in
         start)
            ( start_routing && start_mangle && echo "开始流量控制! TC started!" ) || echo "error."
                        
            exit 0
            ;;

         stop)
            ( stop_routing && stop_mangle && echo "停止流量控制! TC stopped!" ) || echo "error."
            
            exit 0
            ;;
         restart)
            stop_routing
            stop_mangle
            start_routing
            start_mangle
            
            echo "流量控制规则重新装载!"
            ;;
         status)
            status
            ;;
            
         mangle)
            echo "iptables -t mangle -L (显示目前mangle表表标记详细):"
            iptables -t mangle -nL
            ;;

          
         *) usage
            exit 1
            ;;
      esac
      ;;

   *)
      echo " (!) Error: Unknown kernel version. check it !"
      exit 1
      ;;
esac
#三.结束语
#1. 如果要支持htb,请到相关网站下载有关补丁.
#此脚本是参考http://lartc.org 和 http://luxik.cdi.cz/~devik/qos/htb/ 和http://www.docum.org/docum.org
#和听取chinaunix.net的C++版主JohnBull的"Linux的高级路由和流量控制北京沙龙讲座录音
#及关于<<Linux的高级路由和流量控制HOWTO中文版>;>;,经过不断调试得出的总结结果,在此感谢所有作出贡献的人.
#2. iptables,在http://www.iptables.org/ .iptables v1.2.7a 和tc是Red hat linux 9.0下自带的版本.
#3. 此脚本已经在Red Hat Linux 9.0内核2.4.20上,内网约70台频繁上网机器的环境下运行数月,事实证明良好.
#4. 如果ADSL带宽不同或有变,调节相关rate参数及ceil参数即可.
#5. 还有,如果结合IMQ,IMQ(Intermediate queueing device,中介队列设备)把上行和下行都进行分类控制
#就更理想了,但要支持IMQ,就要重新编译内核.关于补丁和更多的文档请参阅imq网站http://www.linuximq.net/
#6. 欢迎交流yahoo messegsender: kindgeorge#yahoo.com此脚本将有待不断完善.
#7. 除了ADSL外,还可以进行其他宽带的控制.
#8. 如果看谁老是在网内搞鬼,经常占满带宽,就把它列为黑名单,并派到"无所谓的数据通道",以防无所谓的人
#在阻碍正务: iptables -t mangle -I PREROUTING 1 -s 192.168.xxx.xxx -j MARK --set-mark 6
#            iptables -t mangle -I PREROUTING 2 -s 192.168.xxx.xxx -j RETURN
#9.使用方法: 整篇文档拷贝后,chmod +x tc2 ,
#执行脚本: ./tc2 start (或其他参数start | stop | restart | status | mangle )即可
#如果想每次在ppp启动时就启动,则在/etc/ppp/ip-up 文件里面加上一句: /路径/tc2 restart
echo "script done!"
exit 1
#end----------------------------------------------------------------------------------------
