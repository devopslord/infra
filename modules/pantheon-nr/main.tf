resource "newrelic_alert_channel" "slack" {
  name = "slack"
  type = "slack"

  config {
    url = var.slack_webhook_url
  }
}

resource "newrelic_alert_policy" "low_disk_space" {
  name = "Low Disk Space"
}

resource "newrelic_infra_alert_condition" "low_disk_space" {
  policy_id = newrelic_alert_policy.low_disk_space.id

  name       = "Low Disk Space"
  type       = "infra_metric"
  event      = "StorageSample"
  select     = "diskFreePercent"
  comparison = "below"

  critical {
    duration      = var.low_disk_space_critical_duration
    value         = var.low_disk_space_critical_value
    time_function = "all"
  }

  warning {
    duration      = var.low_disk_space_warning_duration
    value         = var.low_disk_space_warning_value
    time_function = "all"
  }
}

resource "newrelic_alert_policy_channel" "low_disk_space" {
  policy_id = newrelic_alert_policy.low_disk_space.id
  channel_ids = [
    newrelic_alert_channel.slack.id
  ]
}



resource "newrelic_alert_policy" "high_cpu_usage" {
  name = "High CPU Usage"
}

resource "newrelic_infra_alert_condition" "high_cpu_usage" {
  policy_id = newrelic_alert_policy.high_cpu_usage.id

  name       = "High CPU Usage"
  type       = "infra_metric"
  event      = "SystemSample"
  select     = "cpuPercent"
  comparison = "above"

  critical {
    duration      = var.high_cpu_usage_critical_duration
    value         = var.high_cpu_usage_critical_value
    time_function = "all"
  }

  warning {
    duration      = var.high_cpu_usage_warning_duration
    value         = var.high_cpu_usage_warning_value
    time_function = "all"
  }
}

resource "newrelic_alert_policy_channel" "high_cpu_usage" {
  policy_id = newrelic_alert_policy.high_cpu_usage.id
  channel_ids = [
    newrelic_alert_channel.slack.id
  ]
}



resource "newrelic_alert_policy" "high_mem_usage" {
  name = "High Memory Usage"
}

resource "newrelic_infra_alert_condition" "high_mem_usage" {
  policy_id = newrelic_alert_policy.high_mem_usage.id

  name       = "High Memory Usage"
  type       = "infra_metric"
  event      = "SystemSample"
  select     = "memoryUsedPercent"
  comparison = "above"

  critical {
    duration      = var.high_mem_usage_critical_duration
    value         = var.high_mem_usage_critical_value
    time_function = "all"
  }

  warning {
    duration      = var.high_mem_usage_warning_duration
    value         = var.high_mem_usage_warning_value
    time_function = "all"
  }
}

resource "newrelic_alert_policy_channel" "high_mem_usage" {
  policy_id = newrelic_alert_policy.high_mem_usage.id
  channel_ids = [
    newrelic_alert_channel.slack.id
  ]
}



resource "newrelic_alert_policy" "not_reporting" {
  name = "Not Reporting"
}

resource "newrelic_infra_alert_condition" "not_reporting" {
  policy_id = newrelic_alert_policy.not_reporting.id

  name = "Not Reporting"
  type = "infra_host_not_reporting"

  critical {
    duration = var.not_reporting_critical_duration
  }
}

resource "newrelic_alert_policy_channel" "not_reporting" {
  policy_id = newrelic_alert_policy.not_reporting.id
  channel_ids = [
    newrelic_alert_channel.slack.id
  ]
}
