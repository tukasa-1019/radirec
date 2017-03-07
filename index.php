<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>RadiRec</title>
  <link href="css/bootstrap.min.css" rel="stylesheet">
  <script src="js/jquery-1.12.4.min.js"></script>
  <script src="js/bootstrap.min.js"></script>
  <script>
  function verify(form) {
    if (!form.sun.checked &&
        !form.mon.checked &&
        !form.tue.checked &&
        !form.wed.checked &&
        !form.thu.checked &&
        !form.fri.checked &&
        !form.sat.checked) {
      window.alert('曜日が１つもチェックされていません。');
      return false;
    }
    return true;
  }
  </script>
</head>

<?php

//var_dump($_POST);

include 'job.php';

function printTr($job)
{
  echo sprintf("    <tr>\n");
  echo sprintf("      <td>%d</td>\n", $job->id);
  echo sprintf("      <td>%s</td>\n", htmlspecialchars(JobManager::CHANNELS[$job->channel]));
  echo sprintf("      <td>\n");
  echo sprintf("        <ul class=\"list-inline\">\n");
  echo sprintf("          <li style=\"padding:0; color:%s;\">日</li>\n", in_array(0, $job->week) ? '#f33' : '#fcc');
  echo sprintf("          <li style=\"padding:0; color:%s;\">月</li>\n", in_array(1, $job->week) ? '#333' : '#ccc');
  echo sprintf("          <li style=\"padding:0; color:%s;\">火</li>\n", in_array(2, $job->week) ? '#333' : '#ccc');
  echo sprintf("          <li style=\"padding:0; color:%s;\">水</li>\n", in_array(3, $job->week) ? '#333' : '#ccc');
  echo sprintf("          <li style=\"padding:0; color:%s;\">木</li>\n", in_array(4, $job->week) ? '#333' : '#ccc');
  echo sprintf("          <li style=\"padding:0; color:%s;\">金</li>\n", in_array(5, $job->week) ? '#333' : '#ccc');
  echo sprintf("          <li style=\"padding:0; color:%s;\">土</li>\n", in_array(6, $job->week) ? '#33f' : '#ccf');
  echo sprintf("        </ul>\n");
  echo sprintf("      </td>\n");
  echo sprintf("      <td class=\"text-center\">%02d:%02d</td>\n", $job->hour, $job->minute);
  echo sprintf("      <td class=\"text-center\">%d分</td>\n", (int) ($job->rtime / 60));
  echo sprintf("      <td>%s</td>\n", $job->title);
  echo sprintf("      <td>%s</td>\n", $job->fname);
  echo sprintf("      <td>\n");
  echo sprintf("        <form class=\"form-inline\" action=\"index.php\" method=\"post\">\n");
  echo sprintf("          <input type=\"hidden\" name=\"id\" value=\"%d\">\n", $job->id);
  if ($job->enable) {
    echo sprintf("          <button class=\"btn btn-xs btn-default\" name=\"disable\">無効</button>\n");
  } else {
    echo sprintf("          <button class=\"btn btn-xs btn-primary\" name=\"enable\">有効</button>\n");
    echo sprintf("          <button class=\"btn btn-xs btn-danger\" name=\"remove\">削除</button>\n");
  }
  echo sprintf("        </form>\n");
  echo sprintf("      </td>\n");
  echo sprintf("    </tr>\n");
}

$jobManager = new JobManager();
$ret = true;
if (array_key_exists('append', $_POST)) {
  $channel = $_POST['channel'];
  $minute = (int) $_POST['minute'];
  $hour = (int) $_POST['hour'];
  $week = array();
  if (array_key_exists('sun', $_POST)) { $week[] = 0; }
  if (array_key_exists('mon', $_POST)) { $week[] = 1; }
  if (array_key_exists('tue', $_POST)) { $week[] = 2; }
  if (array_key_exists('wed', $_POST)) { $week[] = 3; }
  if (array_key_exists('thu', $_POST)) { $week[] = 4; }
  if (array_key_exists('fri', $_POST)) { $week[] = 5; }
  if (array_key_exists('sat', $_POST)) { $week[] = 6; }
  $rtime = $_POST['rtime'] * 60;
  $title = $_POST['title'];
  $fname = $_POST['fname'];
  $job = new Job(-1, $channel, $minute, $hour, $week, $rtime, $title, $fname, true);
  $ret = $jobManager->append($job);
}
else if (array_key_exists('remove', $_POST)) {
  $id = (int) $_POST['id'];
  $jobManager->remove($id);
}
else if (array_key_exists('disable', $_POST)) {
  $id = (int) $_POST['id'];
  $job = $jobManager->getJob($id);
  if ($job != NULL) {
    $job->enable = false;
    $jobManager->update($job, $id);
  }
}
else if (array_key_exists('enable', $_POST)) {
  $id = (int) $_POST['id'];
  $job = $jobManager->getJob($id);
  if ($job != NULL) {
    $job->enable = true;
    $jobManager->update($job, $id);
  }
}
?>

<body>

<div class="container-fluid" style="max-width:1024px;">

<h3>新規登録</h3>
<form class="form-horizontal" action="index.php" method="post" onsubmit="return verify(this);">
  <div class="form-group">
    <label class="control-label col-sm-2">チャンネル：</label>
    <div class="form-inline col-sm-10">
      <select class="form-control" name="channel">
<?php
foreach (JobManager::CHANNELS as $key => $val) {
  echo sprintf("        <option value=\"%s\"%s>%s</option>\n", $key, $key == 'AGQR' ? ' selected' : '', htmlspecialchars($val));
}
?>
      </select>
    </div>
  </div>
  <div class="form-group">
    <label class="control-label col-sm-2">曜日：</label>
    <div class="form-inline col-sm-10">
      <label class="checkbox-inline"><input type="checkbox" name="sun" value="1">日</label>
      <label class="checkbox-inline"><input type="checkbox" name="mon" value="1">月</label>
      <label class="checkbox-inline"><input type="checkbox" name="tue" value="1">火</label>
      <label class="checkbox-inline"><input type="checkbox" name="wed" value="1">水</label>
      <label class="checkbox-inline"><input type="checkbox" name="thu" value="1">木</label>
      <label class="checkbox-inline"><input type="checkbox" name="fri" value="1">金</label>
      <label class="checkbox-inline"><input type="checkbox" name="sat" value="1">土</label>
    </div>
  </div>
  <div class="form-group">
    <label class="control-label col-sm-2">開始時間：</label>
    <div class="form-inline col-sm-10">
      <select class="form-control" name="hour">
<?php
for ($i = 0; $i < 24; $i++) {
  $selected = '';
  echo sprintf("          <option value=\"%d\"%s>%d</option>\n", $i, $selected, $i);
}
?>
      </select>
      <span>時</span>
      <select class="form-control" name="minute">
<?php
for ($i = 0; $i < 60; $i++) {
  $selected = '';
  echo sprintf("          <option value=\"%d\"%s>%d</option>\n", $i, $selected, $i);
}
?>
      </select>
      <span>分</span>
    </div>
  </div>
  <div class="form-group">
    <label class="control-label col-sm-2">録画時間：</label>
    <div class="form-inline col-sm-10">
      <select class="form-control" name="rtime">
<?php
for ($i = 5; $i <= 300; $i += 5) {
  $selected = $i == 30 ? ' selected' : '';
  echo sprintf("          <option value=\"%d\"%s>%d分</option>\n", $i, $selected, $i);
}
?>
      </select>
    </div>
  </div>
  <div class="form-group">
    <label class="control-label col-sm-2">録画名：</label>
    <div class="col-sm-6">
      <input class="form-control" type="text" name="title" pattern='^[^\\/?:*"><| 　]+$' required>
    </div>
  </div>
  <div class="form-group">
    <label class="control-label col-sm-2">出力名：</label>
    <div class="col-sm-6">
      <input class="form-control" type="text" name="fname" pattern='^[0-9a-z]+$' required>
    </div>
  </div>
  <button class="btn btn-primary col-sm-offset-2" name="append">追加</button>
</form>

<p class="text-right"><a href="http://www.agqr.jp/timetable/streaming.html" target="_blank">超！Ａ＆Ｇ＋番組表</a></p>

<hr>

<h3>有効ジョブ一覧</h3>
<div class="table-responsive">
  <table class="table table-striped table-condensed">
    <tr>
      <th>ID</th>
      <th>チャンネル</th>
      <th>曜日</th>
      <th>開始時間</th>
      <th>録画時間</th>
      <th>録画名</th>
      <th>ファイル名</th>
      <th></th>
    </tr>
<?php
foreach ($jobManager->getJobList() as $job) {
  if ($job->enable) {
    printTr($job);
  }
}
?>
  </table>
</div>

<hr>

<h3>無効ジョブ一覧</h3>
<div class="table-responsive">
  <table class="table table-striped table-condensed">
    <tr>
      <th>ID</th>
      <th>チャンネル</th>
      <th>曜日</th>
      <th>開始時間</th>
      <th>録画時間</th>
      <th>録画名</th>
      <th>ファイル名</th>
      <th></th>
    </tr>
<?php
foreach ($jobManager->getJobList() as $job) {
  if (!$job->enable) {
    printTr($job);
  }
}
?>
  </table>
</div>

<?php
if (!$ret) {
  print "<script>window.alert('追加に失敗しました。局と時間が重複しているか、プログラムのエラーです。');</script>\n";
}
?>

<!--
$ crontab -l
<?php print $jobManager->getCrontab(); ?>
-->

</div>

</body>

</html>

