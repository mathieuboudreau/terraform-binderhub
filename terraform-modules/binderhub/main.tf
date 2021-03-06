resource "random_id" "token" {
  count       = 2
  byte_length = 32
}

data "template_file" "config" {
  template = "${file("${path.module}/assets/config.yaml")}"
  vars = {
    domain    = "${var.domain}"
    cpu_alloc = "${var.cpu_alloc}"
    mem_alloc = "${var.mem_alloc_gb}"
    docker_id = "${var.docker_id}"
  }
}

data "template_file" "secrets" {
  template = "${file("${path.module}/assets/secrets.yaml")}"
  vars = {
    api_token       = "${random_id.token.0.hex}"
    secret_token    = "${random_id.token.1.hex}"
    docker_id       = "${var.docker_id}"
    docker_password = "${var.docker_password}"
  }
}

data "template_file" "pv" {
  template = "${file("${path.module}/assets/pv.yaml")}"
  vars = { }
}

data "template_file" "nginx-ingress" {
  template = "${file("${path.module}/assets/nginx-ingress.yaml")}"
  vars = { }
}

data "template_file" "kube-lego" {
  template = "${file("${path.module}/assets/kube-lego.yaml")}"
  vars = { 
    domain    = "${var.domain}"
    TLS_email = "${var.TLS_email}"    
  }
}

data "template_file" "install-binderhub" {
  template = "${file("${path.module}/assets/install-binderhub.sh")}"
  vars = {
    binder_version = "${var.binder_version}"
    admin_user     = "${var.admin_user}"
  }
}

resource "null_resource" "remote_install" {
  connection {
    user        = "${var.admin_user}"
    host        = "${var.ip}"
  }

  provisioner "file" {
    content     = "${data.template_file.config.rendered}"
    destination = "/home/${var.admin_user}/config.yaml"
  }

  provisioner "file" {
    content     = "${data.template_file.secrets.rendered}"
    destination = "/home/${var.admin_user}/secrets.yaml"
  }

  provisioner "file" {
    content     = "${data.template_file.pv.rendered}"
    destination = "/home/${var.admin_user}/pv.yaml"
  }

  provisioner "file" {
    content     = "${data.template_file.nginx-ingress.rendered}"
    destination = "/home/${var.admin_user}/nginx-ingress.yaml"
  }


  provisioner "file" {
    content     = "${data.template_file.kube-lego.rendered}"
    destination = "/home/${var.admin_user}/kube-lego.yaml"
  }

  provisioner "file" {
    content     = "${data.template_file.install-binderhub.rendered}"
    destination = "/home/${var.admin_user}/install-binderhub.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /home/${var.admin_user}/install-binderhub.sh"
    ]
  }
}
