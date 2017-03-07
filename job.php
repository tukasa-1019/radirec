<?php

class Job
{
  public $channel;
  public $enable;
  public $fname;
  public $hour;
  public $id;
  public $minute;
  public $rtime;
  public $title;
  public $week;

  public function __construct($id, $channel, $minute, $hour, $week, $rtime, $title, $fname, $enable) {
    $this->id      = $id;
    $this->channel = $channel;
    $this->minute  = $minute;
    $this->hour    = $hour;
    $this->week    = $week;
    $this->rtime   = $rtime;
    $this->title   = $title;
    $this->fname   = $fname;
    $this->enable  = $enable;
  }
}

class JobManager
{
  const JOB_FILE_PATH = 'crontab';
  const CRONTAB_PATH = '/usr/bin/crontab';

  const CRON_FORMAT_PATTEN = '|^(#?)([0-9\*\/\*]+) ([0-9\*\/\*]+) \* \* ([0-9,\-]+) (.+) # ID=([0-9]+)$|';
  const COMM_FORMAT_PATTEN = '|^(.+) "(.+)" "(.+)" ([0-9]+) "(.+)"$|';
  const ID_FORMAT_PATTERN  = '|^(## NextID=)([0-9]+)$|';

  const MARGIN = 20;
  const SCRIPT = 'radirec.sh';

  const CHANNELS = [
    // A&G
    "AGQR"           => "超！A&G+",
    "AGQRA"          => "超！A&G+ (音声)",
    // Radiko
    "TBS"            => "TBSラジオ",
    "QRR"            => "文化放送",
    "LFR"            => "ニッポン放送",
    "INT"            => "InterFM897",
    "FMT"            => "TOKYO FM",
    "FMJ"            => "J-WAVE",
    "JOFR"           => "ラジオ日本",
    "BAYFM87"        => "bayfm78",
    "NACK5"          => "NACK5",
    "YFM"            => "FMヨコハマ",
    "RN1"            => "ラジオNIKKEI第1",
    "RN2"            => "ラジオNIKKEI第2",
    "HOUSOU-DAIGAKU" => "放送大学",
  ];

  private $jlist;

  public function __construct() {
    // Make job file
    if (!file_exists(self::JOB_FILE_PATH)) {
      $fp = fopen(self::JOB_FILE_PATH, 'w');
      fwrite($fp, '## NextID=1');
      fclose($fp);
    }
    $this->reload();
  }

  public function append($job) {
    // avoid append same schedule
    $getStartEndFromJob = function($job, $week, &$start, &$end) {
      $start = ($week * 1440 + $job->hour * 60 + $job->minute) % 10080;
      $end   = ($start + $job->rtime / 60) % 10080;
      if ($start > $end) {
        $start -= 10080;
      }
    };
    foreach ($job->week as $week) {
      $start = $end = 0;
      $getStartEndFromJob($job, $week, $start, $end);
      foreach ($this->jlist as $j) {
        if ($job->channel == $j->channel) {
          foreach ($j->week as $w) {
            $s = $e = 0;
            $getStartEndFromJob($j, $w, $s, $e);
            if (($start > $s && $start < $e) ||
                ($end   > $s && $end   < $e) ||
                ($start < $s && $end   > $e)) {
              //echo $job->fname . "(" . $start . "/" . $end . ")";
              //echo $j->fname . "(" . $s . "/" . $e . ")";
              return false;
            }
          }
        }
      }
    }
    return $this->update($job);
  }

  public function getCrontab() {
    exec(sprintf('%s -l', self::CRONTAB_PATH), $out, $ret);
    $o = '';
    foreach ($out as $line) {
      $o .= sprintf("%s\n", $line);
    }
    return $o;
  }

  public function getJob($id) {
    foreach ($this->jlist as $job) {
      if ($id == $job->id) {
        return $job;
      }
    }
    return NULL;
  }

  public function getJobList() {
    return $this->jlist;
  }

  public function remove($id) {
    return $this->update(NULL, $id);
  }

  public function update($job, $id = -1) {
    if ($fp = fopen(self::JOB_FILE_PATH, 'r+')) {
      // buffer
      $lines = '';

      // lock
      flock($fp, LOCK_EX);

      if ($id > -1) {
        while ($line = fgets($fp)) {
          if (preg_match(self::CRON_FORMAT_PATTEN, $line, $matches)) {
            if ($id == (int) $matches[6]) {
              if ($job) {
                // update line
                $lines .= $this->createLine($job);
              } else {
                // remove line
              }
              continue;
            }
          }
          $lines .= sprintf("%s", $line);
        }
      } else {
        $nid = 0;
        while ($line = fgets($fp)) {
          if (preg_match(self::ID_FORMAT_PATTERN, $line, $matches)) {
            $nid = (int) $matches[2];
            $line = sprintf("%s%d\n", $matches[1], $nid + 1);
          }
          $lines .= $line;
          #sprintf("%s", $line);
        }
        $job->id = $nid;
        // append line
        $lines .= $this->createLine($job);
      }

      // overwrite
      fseek($fp, 0);
      ftruncate($fp, 0);
      fwrite($fp, $lines);

      // apply
      $this->updateCrontab();

      // unlock
      fclose($fp);

      // refresh list
      $this->reload();
    } else {
      return false;
    }
    return true;
  }

  private function createLine($job) {
    $delay = (self::MARGIN % 60 + 60) % 60;
    $padding = (int) (self::MARGIN / 60) + ($delay > 0 ? 1 : 0);

    $minute = ($job->minute + (60 - $padding)) % 60;
    $hour = ($minute <= $job->minute) ? $job->hour : ($job->hour + 23) % 24;

    $week = '';
    foreach ($job->week as $value) {
      if ($job->minute == 0 && $job->hour == 0) {
        $value = ($value + 6) % 7;
      }
      $week .= sprintf('%d,', $value);
    }
    if (strlen($week) > 0) {
      $week = substr($week, 0, -1);
    }

    $script = sprintf('%s/%s', dirname(__FILE__), self::SCRIPT);
    $comm = sprintf('%s "%s" "%s" %d "%s" # ID=%d',
      $script, $job->channel, $job->title, $job->rtime, $job->fname, $job->id);

    return sprintf("%s%d %d * * %s %s\n",
      $job->enable ? '' : '#', $minute, $hour, $week, $comm);
  }

  private function reload() {
    if (isset($this->jlist)) {
      unset($this->jlist);
    }
    $this->jlist = array();

    $lines = file(self::JOB_FILE_PATH);
    foreach ($lines as $line) {
      if (preg_match(self::CRON_FORMAT_PATTEN, $line, $matches)) {
        $padding = (int) (self::MARGIN / 60) + (self::MARGIN % 60 != 0 ? 1 : 0);
        $enable  = empty($matches[1]);
        $minute  = ($matches[2] + $padding) % 60;
        $hour    = ($minute >= (int) $matches[2]) ? (int) $matches[3] : ($matches[3] + 1) % 24;
        $week    = array_map('intval', explode(',', $matches[4]));
        $id      = (int) $matches[6];

        // Straddle the date
        if ($minute == 0 && $hour == 0) {
          foreach ($week as $key => $value) {
            $week[$key] = ($value + 1) % 7;
          }
        }

        if (preg_match(self::COMM_FORMAT_PATTEN, $matches[5], $matches)) {
          /* $script  = $matches[1]; */
          $channel = $matches[2];
          $title   = $matches[3];
          $rtime   = $matches[4];
          $fname   = $matches[5];

          // Append
          $this->jlist[] = new Job($id, $channel, $minute, $hour, $week, $rtime, $title, $fname, $enable);
        }
      }
    }
  }

  private function updateCrontab() {
    exec(sprintf('%s < %s', self::CRONTAB_PATH, self::JOB_FILE_PATH), $out, $ret);
  }
}

?>

