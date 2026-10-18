check "nginx_test_03" {
  data "http" "nginx" {
    url = "http://${module.vm["test-03"].ip}"
  }
  assert {
    condition     = data.http.nginx.status_code == 200
    error_message = "Nginx is not responding with status code 200 on VM test-03 with IP ${module.vm["test-03"].ip}"
  }
}
check "nginx_test_04" {
  data "http" "nginx1" {
    url = "http://${module.vm["test-04"].ip}"
  }
  assert {
    condition     = data.http.nginx1.status_code == 200
    error_message = "Nginx is not responding with status code 200 on VM test-04 with IP ${module.vm["test-04"].ip}"
  }
}