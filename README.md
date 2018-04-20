# 要解决的问题
一直以来sspanel v3通过数据库连接到前端有个问题，后端节点经常由于网络问题联络不到前端于是就会停止发送呼吸包，而网络恢复了之后一定几率后端不会主动嗅探重新发送呼吸包，但是其实python后端还在运行，也就是节点其实可以正常连接，但是前端会报节点失联，并不会统计流量。

# 思路
- 要解决这个问题最好的办法肯定是直接修改后端脚本，奈何本人python还半生不熟，改了几次都没成功，所以决定采用PLAN2，暴力解决。
- 思路很简单，前端建立一个api返回节点是否在线信息，后端定时调用api，如果判断前端显示节点已经掉线，后端python脚本就自动重启。

# 使用方法
**1. 首先在前端网站建立api**
- 修改你的网站目录下/app/HomeController.php文件<br>**添加引用**<br> `use App\Models\Node;`<br>**添加函数**<br>
  ```
  public function check($request,$response, $args)
	{
		$id = $request->getParam("id");
		$node = Node::where('id',"=",$id)->first();
		if ($node=="")
		{
			$status=-1;
		}
		else
		{
			if ($node->isNodeOnline() !== null) {
            if ($node->isNodeOnline() == false) {
							$status=2;
            } else {
              $status=1;
            }
       } else {
							$status=-1;
       }
		}
    ```

- 修改网站目录下/config/routes.php<br>**在// Home后面添加一行**<br>`$app->get('/check', 'App\Controllers\HomeController:check');`

- 在网站目录/resources/views/material/下新建一个文件check.tpl，文件内容只需要写`{$status}`就可以了

**2. 测试api**
- 在浏览器打开网址**http(s)://你的域名/check?id=nodeid**，把nodeid换成你的节点id

- 返回结果如果是1代表节点正常，2代表前端认为节点离线，-1代表节点不存在

- 如果返回可以接收，则前端api就成功做好了，下面ssh进入你要监测的后端服务器

**3. 后端自动监控重启**
- 通过git或者其他方式下载check.sh到你的后端服务器

- 赋予执行权限`chmod 777 check.sh`

- 执行`vi check.sh`，修改你的节点id，网站域名，以及倒数第五行你的后端脚本run.sh的存放目录，然后保存

- 测试执行`bash check.sh`，查看有无报错

- 如没有问题，加入crond定时任务，建议5-10分钟执行一次，执行`crontab -e`，添加一行<br>`*/10 * * * * /root/check.sh`<br>注意/root/check.sh是我的脚本目录，你要改成你自己的

- 搞定收工

# 注意事项
- 第3步中check.sh脚本默认你使用的是./run.sh的方法运行的后端，如果你用的是supervisord或者pm2或者systemd管理的后端，请把check.sh中``bash run.sh``改成你自己重启后端的命令就可以了，例如``service supervisord restart``或者``pm2 restart all``或者``systemctl restart ssr.service``
- 脚本默认每次执行每隔10秒钟调用一次api，共调用5次，5次调用结果只要有一次是1就判定为节点正常
- 不用担心调用api失败节点无限重启，如果调用api超时（超过10s）程序会自动结束当次调用，节点不会有任何动作
