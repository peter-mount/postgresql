// Repository name use, must end with / or be '' for none
repository= 'area51/'

// image prefix
imagePrefix = 'postgres'

// The image version, master branch is latest in docker
version=BRANCH_NAME
if( version == 'master' ) {
  version = '9.6'
}

// The architectures to build, in format recognised by docker
architectures = [ 'amd64', 'arm64v8' ]

// The slave label based on architecture
def slaveId = {
  architecture -> switch( architecture ) {
    case 'amd64':
      return 'AMD64'
    case 'arm64v8':
      return 'ARM64'
    default:
      return 'amd64'
  }
}

// The docker image name
// architecture can be '' for multiarch images
def dockerImage = {
  architecture -> repository + imagePrefix + ':' +
    ( architecture=='' ? '' : ( architecture + '-' ) ) +
    version
}

// The go arch
def goarch = {
  architecture -> switch( architecture ) {
    case 'amd64':
      return 'amd64'
    case 'arm32v6':
    case 'arm32v7':
      return 'arm'
    case 'arm64v8':
      return 'arm64'
    default:
      return architecture
  }
}

properties( [
  buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '7', numToKeepStr: '10')),
  disableConcurrentBuilds(),
  disableResume()
])

architectures.each {
  architecture -> node( slaveId( architecture ) ) {
    stage( "Checkout " + architecture ) {
      checkout scm
    }

    stage( 'Prepare ' + architecture ) {
      sh 'docker pull postgres:' + version
    }

    stage( 'Build ' + architecture ) {
      sh 'docker build -t ' + dockerImage( architecture ) + ' .'
    }

    stage( 'Publish ' + architecture ) {
      sh 'docker push ' + dockerImage( architecture )
    }
  }
}

node( "AMD64" ) {
  stage( 'Publish MultiArch' ) {
    // The manifest to publish
    multiImage = dockerImage( '' )

    // Create/amend the manifest with our architectures
    manifests = architectures.collect { architecture -> dockerImage( architecture ) }
    sh 'docker manifest create -a ' + multiImage + ' ' + manifests.join(' ')

    // For each architecture annotate them to be correct
    architectures.each {
      architecture -> sh 'docker manifest annotate' +
        ' --os linux' +
        ' --arch ' + goarch( architecture ) +
        ' ' + multiImage +
        ' ' + dockerImage( architecture )
    }

    // Publish the manifest
    sh 'docker manifest push -p ' + multiImage
  }
}
